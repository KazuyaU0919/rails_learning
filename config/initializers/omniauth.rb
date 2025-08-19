Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch("GOOGLE_CLIENT_ID", nil),
           ENV.fetch("GOOGLE_CLIENT_SECRET", nil),
           prompt: "select_account" # 複数アカウント持ち向け

  provider :github,
           ENV.fetch("GITHUB_CLIENT_ID", nil),
           ENV.fetch("GITHUB_CLIENT_SECRET", nil),
           scope: "user:email"
end

# GET でコールバックできるように（Rails7 以降の推奨設定）
OmniAuth.config.allowed_request_methods = %i[get]

# 開発中のログが欲しければ
OmniAuth.config.logger = Rails.logger
