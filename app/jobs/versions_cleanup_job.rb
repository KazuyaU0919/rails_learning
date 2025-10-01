# app/jobs/versions_cleanup_job.rb
class VersionsCleanupJob < ApplicationJob
  queue_as :default

  def perform
    keep_n   = Rails.configuration.x.versions.keep_per_item
    keep_day = Rails.configuration.x.versions.keep_days
    batch    = Rails.configuration.x.versions.cleanup_batch

    cutoff = keep_day.positive? ? keep_day.days.ago : nil

    # ① 期限切れ（作成日時が古い）を削除
    if cutoff
      PaperTrail::Version.where("created_at < ?", cutoff).in_batches(of: batch) { |rel| rel.delete_all }
    end

    # ② 各 item ごとに最新 keep_n を残し、それ以外を削除
    return if keep_n <= 0

    # item_type, item_id の組でグルーピングして古いものを削る
    PaperTrail::Version.
      select(:item_type, :item_id).
      distinct.
      in_batches(of: 500) do |pairs|
        pairs.each do |pair|
          scope = PaperTrail::Version.
                    where(item_type: pair.item_type, item_id: pair.item_id).
                    order(created_at: :desc, id: :desc)
          ids_to_keep = scope.limit(keep_n).pluck(:id)
          next if ids_to_keep.empty?
          PaperTrail::Version.
            where(item_type: pair.item_type, item_id: pair.item_id).
            where.not(id: ids_to_keep).
            in_batches(of: batch) { |rel| rel.delete_all }
        end
      end
  end
end
