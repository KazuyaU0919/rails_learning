# app/models/user.rb
class User < ApplicationRecord
  # bcrypt
  has_secure_password validations: false

  # ---------- アソシエーション ----------
  has_many :pre_codes, dependent: :destroy
  has_many :likes,      dependent: :destroy
  has_many :used_codes, dependent: :destroy

  # ---------- 正規化 ----------
  before_validation :normalize_email

  # ---------- バリデーション ----------
  # 共通
  validates :name, presence: true, length: { maximum: 50 }

  # 通常ログイン（provider が空のとき）
  with_options if: -> { provider.blank? } do
    validates :email, presence: true, length: { maximum: 255 },
                      format: { with: URI::MailTo::EMAIL_REGEXP }
  end

  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  # 外部ログイン（provider があるとき）
  with_options if: -> { provider.present? } do
    validates :provider, presence: true
    validates :uid,      presence: true
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

  # ---------- OmniAuth ユーザー作成/取得 ----------
  # auth は OmniAuth::AuthHash 想定
  def self.find_or_create_from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    # 名前・メール（GitHub等はメールが取れない場合あり）
    user.name  ||= auth.dig(:info, :name).presence || auth.dig(:info, :nickname).presence || "User"
    user.email ||= auth.dig(:info, :email)

    # パスワード未設定ならダミーを入れておく（has_secure_passwordの都合）
    user.password = SecureRandom.hex(16) if user.password_digest.blank?

    user.save!
    user
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  # 「通常ログイン」かつ「新規作成 or パスワードを入力しているとき」だけ必須
  def password_required?
    provider.blank? && (new_record? || password.present?)
  end
end
