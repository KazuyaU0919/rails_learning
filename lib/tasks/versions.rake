# lib/tasks/versions.rake
# ============================================================
# 目的:
#   PaperTrail の versions テーブルを、保持期間・件数上限にもとづき
#   定期的にクリーンアップする。
#
# 実行例:
#   bin/rails versions:cleanup
#
# 注意:
#   実際の削除ロジックは VersionsCleanupJob に委譲。
# ============================================================

namespace :versions do
  # =======================
  # PaperTrail バージョンのクリーンアップ
  # =======================
  desc "PaperTrail の履歴を保持ポリシーに従って削除する"
  task cleanup: :environment do
    VersionsCleanupJob.perform_now
    puts "Versions cleanup finished."
  end
end
