class BookSectionsController < ApplicationController
  before_action :set_book
  helper_method :logged_in?

  def show
    # ネストURLなので同一Book内に限定して安全に検索
    @section = @book.book_sections.find(params[:id])

    # ★未ログインかつ FREE でなければログインへ
    unless @section.is_free? || logged_in?
      # 可能なら戻り先を保存（アプリに store_location があれば）
      if respond_to?(:store_location, true)
        store_location(book_section_path(@book, @section))
      end
      redirect_to(new_session_path, alert: "このページを表示するにはログインが必要です")
      return
    end

    # 表示継続（前後リンク用）
    @prev = @section.previous
    @next = @section.next
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  # アプリに既に同等のヘルパがあるなら不要。無ければ簡易版を用意。
  def logged_in?
    !!current_user
  end
end
