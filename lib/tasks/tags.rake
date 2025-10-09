# lib/tasks/tags.rake
namespace :tags do
  desc "未使用が一定期間続くタグを削除（既定: 10日）"
  task :cleanup_unused, [ :days ] => :environment do |_t, args|
    days = (args[:days].presence || 10).to_i
    puts "[tags:cleanup_unused] start (days=#{days})"
    Tag.cleanup_unused!(older_than: days.days)
    puts "[tags:cleanup_unused] done"
  end
end
