class BooksController < ApplicationController
  # 一覧：本＋セクション数のN+1を防ぐ
  def index
    @books = Book
      .includes(:book_sections)          # N+1回避
      .order(id: :asc)
  end

  # 詳細：目次も一緒に
  def show
    @book     = Book.includes(:book_sections).find(params[:id])
    @sections = @book.book_sections       # 既に order(:position) が効く
  end
end
