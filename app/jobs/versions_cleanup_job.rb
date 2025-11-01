# ============================================================
# Job: VersionsCleanupJob
# ------------------------------------------------------------
# PaperTrail の Version レコードを定期的に整理。
# - 古すぎる履歴を削除
# - 各アイテムごとに最新 N 件のみ保持
# ============================================================
class VersionsCleanupJob < ApplicationJob
  queue_as :default

  def perform
    keep_n   = Rails.configuration.x.versions.keep_per_item
    keep_day = Rails.configuration.x.versions.keep_days
    batch    = Rails.configuration.x.versions.cleanup_batch

    cutoff = keep_day.positive? ? keep_day.days.ago : nil

    # =======================
    # ① 期限切れ履歴の削除
    # =======================
    if cutoff
      PaperTrail::Version.where("created_at < ?", cutoff)
                         .in_batches(of: batch) { |rel| rel.delete_all }
    end

    # =======================
    # ② 各アイテムごとに最新 keep_n を残す
    # =======================
    return if keep_n <= 0

    PaperTrail::Version
      .select(:item_type, :item_id)
      .distinct
      .in_batches(of: 500) do |pairs|
        pairs.each do |pair|
          scope = PaperTrail::Version
                    .where(item_type: pair.item_type, item_id: pair.item_id)
                    .order(created_at: :desc, id: :desc)
          ids_to_keep = scope.limit(keep_n).pluck(:id)
          next if ids_to_keep.empty?

          PaperTrail::Version
            .where(item_type: pair.item_type, item_id: pair.item_id)
            .where.not(id: ids_to_keep)
            .in_batches(of: batch) { |rel| rel.delete_all }
        end
      end
  end
end
