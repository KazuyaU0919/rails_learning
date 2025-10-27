# lib/tasks/digest.rake
# ============================================================
# 目的:
#   管理者向けダイジェスト通知の実行タスク群。
#   - 前直近1時間のダイジェスト送信
#   - 任意の過去 N 分のウィンドウでダイジェスト送信
#
# 実行例:
#   bin/rails digest:hourly
#   bin/rails digest:window[5]       # 直近5分
#   MINUTES=90 bin/rails digest:window
#
# 注意:
#   ジョブ実行自体は HourlyDigestJob に委譲。ここでは
#   実行ウィンドウの算出とログ出力のみを行う。
# ============================================================

namespace :digest do
  # =======================
  # 前直近1時間ぶんのダイジェスト
  # =======================
  desc "直近1時間（前の1時間）の管理ダイジェストを送信する"
  task hourly: :environment do
    HourlyDigestJob.perform_now
    puts "[digest:hourly] done at #{Time.zone.now}"
  end

  # =======================
  # 任意の過去 N 分のダイジェスト
  # =======================
  # 引数:
  #   minutes（省略時は ENV.MINUTES または 60）
  # 例:
  #   bin/rails digest:window[15]
  #   MINUTES=30 bin/rails digest:window
  desc "過去 N 分の管理ダイジェストを送信（既定: 60分）"
  task :window, [:minutes] => :environment do |_t, args|
    minutes      = (args[:minutes] || ENV.fetch("MINUTES", "60")).to_i
    window_end   = Time.zone.now
    window_start = window_end - minutes.minutes

    HourlyDigestJob.perform_now(window_start:, window_end:)
    puts "[digest:window] minutes=#{minutes}, ran at #{Time.zone.now}"
  end
end
