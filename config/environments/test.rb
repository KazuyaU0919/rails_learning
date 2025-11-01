# =========================================================
# File: config/environments/test.rb
# ---------------------------------------------------------
# 目的:
#   - テスト環境での挙動設定。
#   - データは毎回リセットされるため、速度・安定性・独立性を重視。
# =========================================================

Rails.application.configure do
  # =======================
  # コードロード・リロード
  # =======================
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?

  # =======================
  # 静的ファイルとキャッシュ
  # =======================
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }
  config.cache_store = :null_store
  config.consider_all_requests_local = true

  # =======================
  # 例外 / フォージェリ保護
  # =======================
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false

  # =======================
  # ストレージ
  # =======================
  config.active_storage.service = :test

  # =======================
  # メール設定
  # =======================
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: "example.com" }

  # =======================
  # ジョブアダプタ
  # =======================
  config.active_job.queue_adapter = :test

  # =======================
  # デバッグ / デプリケーション
  # =======================
  config.active_support.deprecation = :stderr

  # =======================
  # i18n / View / before_actionチェック
  # =======================
  # config.i18n.raise_on_missing_translations = true
  # config.action_view.annotate_rendered_view_with_filenames = true
  config.action_controller.raise_on_missing_callback_actions = true
end
