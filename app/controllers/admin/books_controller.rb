# app/controllers/admin/books_controller.rb
# ============================================================
# 管理: 書籍（Book）
# ------------------------------------------------------------
# ・基本 CRUD
# ・一覧は position 昇順 / 更新降順で視認性向上
# ============================================================
class Admin::BooksController < Admin::BaseController
  layout "admin"

  # =======================
  # アクション
  # =======================
  def index
    @books = Book.order(position: :asc, updated_at: :desc).page(params[:page])
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    if @book.save
      redirect_to admin_books_path, notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @book = Book.find(params[:id])
  end

  def update
    @book = Book.find(params[:id])
    if @book.update(book_params)
      redirect_to admin_books_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Book.find(params[:id]).destroy
    redirect_to admin_books_path, notice: "削除しました"
  end

  private

  # =======================
  # Strong Parameters
  # =======================
  def book_params
    params.require(:book).permit(:title, :description, :position)
  end
end
