# 本番環境のみCSPを有効化し、Google Analytics 用の許可を追加
if Rails.env.production?
  require "securerandom"

  Rails.application.config.content_security_policy do |policy|
    # 必要なディレクティブだけ追加（他は既定値のまま）
    policy.script_src  :self, :https, "https://www.googletagmanager.com"
    policy.connect_src :self, :https,
                       "https://www.google-analytics.com",
                       "https://www.googletagmanager.com"
    policy.img_src     :self, :https, :data
    policy.frame_src   :self, :https
  end

  # インライン <script> を安全に許可するための nonce 設定
  Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
end
