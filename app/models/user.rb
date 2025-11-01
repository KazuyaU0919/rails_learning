# ============================================================
# User
# ------------------------------------------------------------
# アプリケーションのユーザー。パスワード方式/外部認証の両対応。
# Remember機能・凍結・編集権限の判定・各種関連を保持。
# ============================================================

class User < ApplicationRecord
  # =======================
  # 関連
  # =======================
  has_many :pre_codes, dependent: :destroy
  has_many :likes,      dependent: :destroy
  has_many :used_codes, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_pre_codes, through: :bookmarks, source: :pre_code
  has_many :editor_permissions, dependent: :destroy

  # =======================
  # 認証
  # =======================
  has_secure_password validations: false
  before_validation :normalize_email

  # =======================
  # バリデーション
  # =======================
  validates :name, presence: true, length: { maximum: 50 }

  validates :email,
    presence: true,
    length:  { maximum: 255 },
    format:  { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false },
    if: :email_uniqueness_required?

  # パスワード必須判定は uses_password?（外部認証なしユーザー）に限定
  validates :password, presence: true, if: :password_required?
  # 入力された場合にだけ長さチェック（初回セットも担保）
  validates :password, length: { minimum: 6, maximum: 19 }, allow_nil: true

  # =======================
  # スコープ
  # =======================
  scope :search, ->(q) {
    if q.present?
      where("LOWER(name) LIKE :q OR LOWER(email) LIKE :q", q: "%#{q.to_s.downcase}%")
    end
  }
  scope :editors, -> { where(editor: true) }
  scope :banned,  -> { where.not(banned_at: nil) }

  # =======================
  # 便利メソッド（状態/権限）
  # =======================
  def banned? = banned_at.present?
  def toggle_editor! = update!(editor: !editor)

  def toggle_ban!(reason = nil)
    if banned?
      update!(banned_at: nil, ban_reason: nil)
    else
      update!(banned_at: Time.current, ban_reason: reason)
    end
  end

  # =======================
  # パスワード再設定トークン
  # =======================
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

  # =======================
  # OmniAuth（外部認証）補助
  # =======================
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
    # 16文字のランダム文字列をセット（上限19）
    user.password = SecureRandom.alphanumeric(16) if user.password_digest.blank?
    user.save!

    if authentication.user_id != user.id
      authentication.user = user
      authentication.save!
    end

    user
  end

  # =======================
  # Remember 機能
  # =======================
  def self.new_remember_token = SecureRandom.urlsafe_base64(32)

  def self.digest(str)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(str, cost: cost)
  end

  def remember!
    token = User.new_remember_token
    update_columns(
      remember_digest:     User.digest(token),
      remember_created_at: Time.current,
      updated_at:          Time.current
    )
    token
  end

  def authenticated_remember?(token)
    return false if remember_digest.blank?
    BCrypt::Password.new(remember_digest).is_password?(token)
  end

  def forget! = update_columns(remember_digest: nil, remember_created_at: nil, updated_at: Time.current)
  def revoke_all_remember! = forget!

  def remember_expired?(ttl: 30.days)
    remember_created_at.blank? || remember_created_at < ttl.ago
  end

  # =======================
  # 関連ヘルパ
  # =======================
  def bookmarked?(pre_code) = bookmarks.exists?(pre_code_id: pre_code.id)
  def bookmark_for(pre_code) = bookmarks.find_by(pre_code_id: pre_code.id)

  # 編集権限（管理者/編集者/サブエディタ）
  def can_edit?(record)
    return false if record.nil?
    return true  if admin?
    return true  if editor?
    EditorPermission.exists?(user_id: id, target_type: record.class.name, target_id: record.id)
  end

  def sub_editor? = !admin? && !editor? && editor_permissions.exists?

  def effective_role
    return :admin      if admin?
    return :editor     if editor?
    return :sub_editor if editor_permissions.exists?
    :general
  end

  # ❶ 外部連携の有無（＝従来の「パスワード方式ユーザ」か？）
  def uses_password? = authentications.blank?

  # ❷ パスワードがDBに存在するか（UI判定/表示用）
  def has_password? = password_digest.present?

  private

  # =======================
  # 内部ユーティリティ
  # =======================
  def normalize_email = self.email = email.to_s.strip.downcase.presence

  # 「パスワード必須」判定（外部連携なし かつ 新規 or 入力あり）
  def password_required?
    uses_password? && (new_record? || password.present?)
  end

  def email_uniqueness_required? = uses_password?
end
