# =========================================================
# File: config/schedule.rb
# ---------------------------------------------------------
# 目的:
#   whenever（cron管理ライブラリ）のスケジュール設定。
#   Railsタスクを定期的に実行する。
#
# 構成:
#   - ログ出力先設定
#   - 実行環境設定
#   - 独自ジョブタイプ（rails コマンド）定義
#   - 実際の定期ジョブ（digest:hourly）
# =========================================================

# =======================
# ログ出力設定
# =======================
set :output, { standard: "log/cron.log", error: "log/cron.error.log" }

# =======================
# 環境設定
# =======================
set :environment, ENV.fetch("RAILS_ENV", :development).to_sym
env :PATH, ENV["PATH"]

# =======================
# ジョブタイプ定義
# =======================
# bin/rails を直接呼び出すための型を定義。
job_type :rails, "cd :path && :environment_variable=:environment bin/rails :task :output"

# =======================
# 定期ジョブ定義
# =======================
# 毎時00分に “直前1時間” のダイジェスト処理を実行。
every 1.hour, at: 0 do
  rails "digest:hourly"
end
