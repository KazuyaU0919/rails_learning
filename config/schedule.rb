# config/schedule.rb
# ログ出力
set :output, { standard: "log/cron.log", error: "log/cron.error.log" }

# 環境
set :environment, ENV.fetch("RAILS_ENV", :development).to_sym
env :PATH, ENV["PATH"]

# bin/rails を直接叩く
job_type :rails, "cd :path && :environment_variable=:environment bin/rails :task :output"

# 毎時00分に “直前1時間” のダイジェスト
every 1.hour, at: 0 do
  rails "digest:hourly"
end
