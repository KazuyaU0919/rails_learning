class Admin::DashboardsController < Admin::BaseController
  layout "admin"

  def index
    @books_count = Book.count
    @sections_count = BookSection.count
    # 余力があれば最近更新されたレコードなども追加できる
  end
end
