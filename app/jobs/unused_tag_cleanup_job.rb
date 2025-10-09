# app/jobs/unused_tag_cleanup_job.rb
class UnusedTagCleanupJob < ApplicationJob
  queue_as :default

  # 既定: 10日
  def perform(days: 10)
    Tag.cleanup_unused!(older_than: days.to_i.days)
  end
end
