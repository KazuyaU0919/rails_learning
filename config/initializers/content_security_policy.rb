# =========================================================
# File: config/initializers/content_security_policy.rb
# ---------------------------------------------------------
# 目的:
#   - コンテンツセキュリティポリシー (CSP) 設定。
#   - 本番環境でのみ有効化し、Google Analytics などの外部スクリプトを許可。
# 注意:
#   - nonce を生成して安全なインライン <script> を許可。
# =========================================================

if Rails.env.production?
  require "securerandom"

  Rails.application.config.content_security_policy do |policy|
    # =======================
    # 基本ポリシー
    # =======================
    policy.script_src  :self, :https, "https://www.googletagmanager.com"
    policy.connect_src :self, :https,
                       "https://www.google-analytics.com",
                       "https://www.googletagmanager.com"
    policy.img_src     :self, :https, :data
    policy.frame_src   :self, :https
  end

  # =======================
  # nonce 設定（インラインscript安全化）
  # =======================
  Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
end
