# =========================================================
# File: config/initializers/default_url_options.rb
# ---------------------------------------------------------
# 目的:
#   - URL生成（routes, mailer）のデフォルトホスト設定。
#   - 環境別に host / protocol を切り替える。
# =========================================================

if Rails.env.development?
  # 開発環境：localhost
  options = { host: "localhost", port: 3000, protocol: "http" }
else
  # 本番環境：ENV["APP_HOST"] が優先、なければ example.com
  host = ENV.fetch("APP_HOST", "example.com")
  options = { host:, protocol: "https" }
end

# =======================
# URL生成のデフォルト設定
# =======================
Rails.application.routes.default_url_options = options
ActionMailer::Base.default_url_options = options
