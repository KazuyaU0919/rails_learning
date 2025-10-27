# lib/tasks/tags.rake
# ============================================================
# 目的:
#   PreCode 等に紐付かず未使用の状態が一定日数続いたタグを整理（削除）する。
#
# 実行例:
#   bin/rails tags:cleanup_unused              # 既定 10 日
#   bin/rails tags:cleanup_unused[30]         # 30 日以上未使用のタグを削除
#
# 注意:
#   実際の削除ロジックは Tag.cleanup_unused! に委譲。
# ============================================================

namespace :tags do
  # =======================
  # 未使用タグのクリーンアップ
  # =======================
  # 引数:
  #   days（省略時 10）
  desc "未使用が一定期間続くタグを削除（既定: 10日）"
  task :cleanup_unused, [:days] => :environment do |_t, args|
    days = (args[:days].presence || 10).to_i

    puts "[tags:cleanup_unused] start (days=#{days})"
    Tag.cleanup_unused!(older_than: days.days)
    puts "[tags:cleanup_unused] done"
  end
end
