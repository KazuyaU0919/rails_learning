# lib/tasks/digest.rake
namespace :digest do
  desc "Send hourly admin digests (edits & contacts) for the previous hour"
  task hourly: :environment do
    HourlyDigestJob.perform_now
    puts "[digest:hourly] done at #{Time.zone.now}"
  end

  desc "Send admin digest for last N minutes (default 60). Usage: bin/rails digest:window[5]"
  task :window, [ :minutes ] => :environment do |_t, args|
    minutes = (args[:minutes] || ENV.fetch("MINUTES", "60")).to_i
    window_end   = Time.zone.now
    window_start = window_end - minutes.minutes
    HourlyDigestJob.perform_now(window_start:, window_end:)
    puts "[digest:window] minutes=#{minutes}, ran at #{Time.zone.now}"
  end
end
