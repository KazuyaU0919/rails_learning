# app/controllers/books_controller.rb
class BooksController < ApplicationController
  # 一覧：本＋セクション数のN+1を防ぎつつ必要カラムに絞る
  def index
    @books = Book
      .select(:id, :title, :description, :updated_at, :book_sections_count)
      .includes(:book_sections)                # N+1回避
      .order(position: :asc, updated_at: :desc)
      .page(params[:page])
  end

  # 詳細：目次も一緒に
  def show
    @book = Book.includes(:book_sections).find(params[:id])
    @sections = @book.book_sections           # 既に order(:position) が効く
  end
end
