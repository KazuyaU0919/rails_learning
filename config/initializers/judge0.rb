# =========================================================
# File: config/initializers/judge0.rb
# ---------------------------------------------------------
# 目的:
#   コード実行エンジン Judge0 への接続情報を Rails 設定に集約。
#   環境変数から読み取り、アプリ全体で `Rails.configuration.x.judge0` として参照。
#
# セキュリティ:
#   - 値は必ず環境変数から注入する（ハードコード禁止）。
#   - APIキー等は「機微情報」のため、ログに出さないこと。
# =========================================================

Rails.application.configure do
  config.x.judge0 = {
    base_url: ENV["JUDGE0_BASE_URL"],
    api_key:  ENV["JUDGE0_RAPIDAPI_KEY"],
    host_hdr: ENV["JUDGE0_HOST_HEADER"]
  }
end
