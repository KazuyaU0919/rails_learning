# =========================================================
# File: config/initializers/omniauth.rb
# ---------------------------------------------------------
# 目的:
#   OmniAuth のプロバイダ（Google, GitHub）を設定。
#   認証フローの入口を Rack ミドルウェアとして追加。
#
# セキュリティ/可用性:
#   - クライアントID/シークレットは必ず環境変数から取得（nil 許容は環境差異想定）。
#   - コールバックは Rails 7 以降の推奨どおり GET を許可。
#   - ログは Rails.logger を利用（個人情報は出さないこと）。
# =========================================================

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV.fetch("GOOGLE_CLIENT_ID", nil),
           ENV.fetch("GOOGLE_CLIENT_SECRET", nil),
           prompt: "select_account" # 複数アカウント持ちのユーザー向け

  provider :github,
           ENV.fetch("GITHUB_CLIENT_ID", nil),
           ENV.fetch("GITHUB_CLIENT_SECRET", nil),
           scope: "user:email"
end

# =======================
# リクエストメソッド / ロガー
# =======================
# GET でコールバックできるように（Rails7 以降の推奨設定）
OmniAuth.config.allowed_request_methods = %i[get]

# 開発中のログが欲しければ
OmniAuth.config.logger = Rails.logger
