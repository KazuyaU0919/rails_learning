# app/models/user.rb
class User < ApplicationRecord
  # ---------- アソシエーション ----------
  has_many :pre_codes, dependent: :destroy
  has_many :likes,      dependent: :destroy
  has_many :used_codes, dependent: :destroy
  has_many :authentications, dependent: :destroy

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
