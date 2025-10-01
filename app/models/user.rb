# app/models/user.rb
class User < ApplicationRecord
  # ---------- アソシエーション ----------
  has_many :pre_codes, dependent: :destroy
  has_many :likes,      dependent: :destroy
  has_many :used_codes, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_pre_codes, through: :bookmarks, source: :pre_code
  has_many :editor_permissions, dependent: :destroy

  # bcrypt
  has_secure_password validations: false

  # ---------- 正規化 ----------
  before_validation :normalize_email

  # ---------- バリデーション ----------
  # 共通
  validates :name, presence: true, length: { maximum: 50 }

  # ★ 一意性は「パスワード方式 (= 外部連携なし)」の場合のみチェック
  validates :email,
    presence: true,
    length:  { maximum: 255 },
    format:  { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false },
    if: :email_uniqueness_required?

  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  # ---------- スコープ（検索/フィルタ） ----------
  # 部分一致（大/小文字・全角半角の差を吸収するため、ここでは downcase のみ。
  # さらに高度な正規化が必要なら unaccent や独自正規化を検討）
  scope :search, ->(q) {
    if q.present?
      where("LOWER(name) LIKE :q OR LOWER(email) LIKE :q", q: "%#{q.to_s.downcase}%")
    end
  }

  # 編集者のみ
  scope :editors, -> { where(editor: true) }

  # 凍結中のみ（banned_at が NULL でない）
  scope :banned,  -> { where.not(banned_at: nil) }

  # ---------- 管理用インスタンスメソッド ----------
  # 凍結中か？
  def banned?
    banned_at.present?
  end

  # 編集者フラグのトグル（true/false を切替）
  def toggle_editor!
    update!(editor: !editor)
  end

  # BAN のトグル（理由は任意。設定→解除をトグル）
  def toggle_ban!(reason = nil)
    if banned?
      update!(banned_at: nil, ban_reason: nil)
    else
      update!(banned_at: Time.current, ban_reason: reason)
    end
  end

  # ---------- パスワード再設定 ----------
  def generate_reset_token!
    self.reset_password_token   = SecureRandom.urlsafe_base64(32)
    self.reset_password_sent_at = Time.current
    save!
  end

  def reset_token_valid?(ttl: 30.minutes)
    reset_password_token.present? &&
      reset_password_sent_at.present? &&
      reset_password_sent_at > ttl.ago
  end

  def clear_reset_token!
    update!(reset_password_token: nil, reset_password_sent_at: nil)
  end

  # --------- OmniAuth ユーザー作成/取得（authentications 経由） ----------
  # auth は OmniAuth::AuthHash 想定
  def self.find_or_create_from_omniauth(auth)
    authentication = Authentication.find_or_initialize_by(
      provider: auth.provider, uid: auth.uid
    )

    user = authentication.user ||
           User.find_by(email: auth.dig(:info, :email)) ||
           User.new

    user.name  ||= auth.dig(:info, :name).presence ||
                   auth.dig(:info, :nickname).presence || "User"
    user.email ||= auth.dig(:info, :email)
    user.password = SecureRandom.hex(16) if user.password_digest.blank?
    user.save!

    if authentication.user_id != user.id
      authentication.user = user
      authentication.save!
    end

    user
  end

  # 外部連携が無い (= authentications が空) ユーザーはパスワード方式を使う
  def uses_password?
    authentications.blank?
  end

  # ===== Remember me =====
  # 乱数トークンを生成して返す（プレーン）
  def self.new_remember_token
    SecureRandom.urlsafe_base64(32)
  end

  # 与えられた文字列をBCryptダイジェスト化
  def self.digest(str)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(str, cost: cost)
  end

  # 発行：digest保存 + 発行時刻
  def remember!
    token = User.new_remember_token
    update_columns(
      remember_digest:     User.digest(token),
      remember_created_at: Time.current,
      updated_at:          Time.current
    )
    token
  end

  # 検証：プレーントークンがdigestと一致するか
  def authenticated_remember?(token)
    return false if remember_digest.blank?
    BCrypt::Password.new(remember_digest).is_password?(token)
  end

  # 失効（この端末 or 全端末）
  def forget!
    update_columns(remember_digest: nil, remember_created_at: nil, updated_at: Time.current)
  end

  # パスワード更新時：全端末強制失効（ProfilesController から呼ぶ想定）
  def revoke_all_remember!
    forget!
  end

  # Rememberの有効期限（30日）
  def remember_expired?(ttl: 30.days)
    remember_created_at.blank? || remember_created_at < ttl.ago
  end

  # ---------- ブックマーク設定 ----------
  # その PreCode をブックマーク済みか？
  def bookmarked?(pre_code)
    bookmarks.exists?(pre_code_id: pre_code.id)
  end

  # その PreCode のブックマークオブジェクトを返す（なければ nil）
  def bookmark_for(pre_code)
    bookmarks.find_by(pre_code_id: pre_code.id)
  end

  # ---------- 共同編集の認可 ----------
  # 管理者 or editor フラグ保持者は全ページ編集可
  # それ以外は editor_permissions に該当があれば該当ページのみ編集可
  def can_edit?(record)
    return false if record.nil?
    return true  if admin?
    return true  if editor?

    EditorPermission.exists?(
      user_id: id,
      target_type: record.class.name,
      target_id: record.id
    )
  end

  # sub_editor 相当か？（admin/editor ではなく、個別権限を持っている）
  def sub_editor?
    !admin? && !editor? && editor_permissions.exists?
  end

  # 画面表示用の有効ロール（優先順: admin > editor > sub_editor > general）
  def effective_role
    return :admin       if admin?
    return :editor      if editor?
    return :sub_editor  if editor_permissions.exists?
    :general
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  # 「通常ログイン (= 外部連携なし) で、新規作成 or パスワード入力があるとき」だけ必須
  def password_required?
    uses_password? && (new_record? || password.present?)
  end

  # ★ email 一意性チェックを実行するか
  def email_uniqueness_required?
    uses_password?
  end
end
