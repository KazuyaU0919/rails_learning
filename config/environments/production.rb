# config/environments/production.rb
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ================================
  # 基本動作（本番最適化）
  # ================================
  config.enable_reloading = false          # リクエスト間でコードを再読み込みしない
  config.eager_load       = true           # 起動時に読み込み（パフォーマンス/メモリ最適化）
  config.consider_all_requests_local = false # 本番では詳細エラーを表示しない

  # ================================
  # キャッシュ / 静的ファイル
  # ================================
  config.action_controller.perform_caching = true
  # アセットはダイジェスト付きで配信されるので長期キャッシュOK
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  # config.asset_host = "http://assets.example.com" # 使う場合のみ有効化

  # ================================
  # ファイル保存
  # ================================
  config.active_storage.service = :production

  # ================================
  # SSL / リダイレクト
  # ================================
  # Render はリバースプロキシで TLS 終端するため「SSL 前提」で動かす
  config.assume_ssl = true
  # http で来たアクセスを https へ 301 リダイレクト（安全な Cookie/HSTS も有効化）
  config.force_ssl  = true
  # ※ /up のヘルスチェックだけ http->https リダイレクトを避けたい場合は下記を有効化
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # ================================
  # 許可ホスト（Blocked host 対策）
  # ================================
  # ここに **受け付けるホスト名** を追加する。追加漏れは「Blocked host」エラーになる。
  config.hosts << "rails-learning.com"
  config.hosts << "www.rails-learning.com"
  # 切替検証用に Render の初期 URL も当面許可（不要になったら削除可）
  config.hosts << "rails-learning.onrender.com"

  # Healthcheck をログに出しすぎない
  config.silence_healthcheck_path = "/up"

  # ================================
  # ログ
  # ================================
  config.log_tags  = [ :request_id ]
  config.logger    = ActiveSupport::TaggedLogging.logger(STDOUT)
  # 例: RAILS_LOG_LEVEL=debug で詳細化可（個人情報が出る可能性があるので注意）
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.active_support.report_deprecations = false

  # ================================
  # キャッシュ / ジョブ
  # ================================
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :inline
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # ================================
  # メール（URL 生成・配信設定）
  # ================================
  # メール内の URL で使うホスト名。Render のダッシュボードで APP_HOST を設定しておく想定。
  # 例: APP_HOST=rails-learning.com
  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST"),
    protocol: "https"
  }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV["SMTP_ADDRESS"],
    port:                 ENV.fetch("SMTP_PORT", 587),
    domain:               ENV["SMTP_DOMAIN"],
    user_name:            ENV["SMTP_USERNAME"],
    password:             ENV["SMTP_PASSWORD"],
    authentication:       :login,
    enable_starttls_auto: true
  }
  # credentials を使う場合の雛形（今は未使用）
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password:  Rails.application.credentials.dig(:smtp, :password),
  #   address:   "smtp.example.com",
  #   port:      587,
  #   authentication: :plain
  # }

  # ================================
  # I18n / ActiveRecord
  # ================================
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  # ================================
  # 参考: Host 認可の高度設定（今回は明示 hosts を使用）
  # ================================
  # config.hosts = [
  #   "example.com",          # 例: メインドメイン
  #   /.*\.example\.com/      # 例: サブドメインをまとめて許可
  # ]
  # Host 認可の例外（/up を除外したい場合）
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
