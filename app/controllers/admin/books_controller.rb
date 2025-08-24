class Admin::BooksController < Admin::BaseController
  layout "admin"

  def index
    @books = Book.order(updated_at: :desc).page(params[:page])
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
  def book_params
    params.require(:book).permit(:title, :description)
  end
end
