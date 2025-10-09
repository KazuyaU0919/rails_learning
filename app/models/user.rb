# app/models/user.rb
class User < ApplicationRecord
  has_many :pre_codes, dependent: :destroy
  has_many :likes,      dependent: :destroy
  has_many :used_codes, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_pre_codes, through: :bookmarks, source: :pre_code
  has_many :editor_permissions, dependent: :destroy

  has_secure_password validations: false
  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 50 }

  validates :email,
    presence: true,
    length:  { maximum: 255 },
    format:  { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false },
    if: :email_uniqueness_required?

  validates :password,
    presence: true,
    length: { minimum: 6, maximum: 19 },
    if: :password_required?

  scope :search, ->(q) {
    if q.present?
      where("LOWER(name) LIKE :q OR LOWER(email) LIKE :q", q: "%#{q.to_s.downcase}%")
    end
  }
  scope :editors, -> { where(editor: true) }
  scope :banned,  -> { where.not(banned_at: nil) }

  def banned? = banned_at.present?

  def toggle_editor! = update!(editor: !editor)

  def toggle_ban!(reason = nil)
    if banned?
      update!(banned_at: nil, ban_reason: nil)
    else
      update!(banned_at: Time.current, ban_reason: reason)
    end
  end

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

  # OmniAuth ユーザー作成/取得
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
    # ★ 16 文字に統一（上限 19）
    user.password = SecureRandom.alphanumeric(16) if user.password_digest.blank?
    user.save!

    if authentication.user_id != user.id
      authentication.user = user
      authentication.save!
    end

    user
  end

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

  def bookmarked?(pre_code) = bookmarks.exists?(pre_code_id: pre_code.id)

  def bookmark_for(pre_code) = bookmarks.find_by(pre_code_id: pre_code.id)

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

  # 外部連携が無い (= authentications が空) ユーザーはパスワード方式を使う
  def uses_password? = authentications.blank?

  private

  def normalize_email = self.email = email.to_s.strip.downcase.presence

  def password_required?
    uses_password? && (new_record? || password.present?)
  end

  def email_uniqueness_required? = uses_password?
end
