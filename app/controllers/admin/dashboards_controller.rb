# app/controllers/admin/dashboards_controller.rb
# ============================================================
# 管理: ダッシュボード
# ------------------------------------------------------------
# ・サイト全体のサマリー表示（件数など）
# ・今後の拡張: 直近の更新、アクティビティなど
# ============================================================
class Admin::DashboardsController < Admin::BaseController
  layout "admin"

  # =======================
  # アクション
  # =======================
  def index
    @books_count    = Book.count
    @sections_count = BookSection.count
    # TODO: 最近更新/トレンドなどの統計を足していける拡張ポイント
  end
end
