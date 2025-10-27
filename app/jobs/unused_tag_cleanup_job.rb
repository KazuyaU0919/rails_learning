# ============================================================
# Job: UnusedTagCleanupJob
# ------------------------------------------------------------
# 使用されていないタグを定期的に削除するジョブ。
# 既定値: 10日以上未使用のタグを削除。
# ============================================================
class UnusedTagCleanupJob < ApplicationJob
  queue_as :default

  # =======================
  # メイン処理
  # =======================
  def perform(days: 10)
    Tag.cleanup_unused!(older_than: days.to_i.days)
  end
end
