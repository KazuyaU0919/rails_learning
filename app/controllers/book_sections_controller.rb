class BookSectionsController < ApplicationController
  before_action :set_book

  def show
    # ネストURLなので同一Book内に限定して安全に検索
    @section = @book.book_sections.find(params[:id])
    @prev    = @section.previous
    @next    = @section.next
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end
end
