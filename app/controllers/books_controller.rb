# ============================================================
# BooksController
# ------------------------------------------------------------
# 教本（Book）の一覧・詳細表示を担当。
# ------------------------------------------------------------
# 主な責務：
#   - Book 一覧（N+1回避 + 必要カラム絞り）
#   - Book 詳細（目次付き）
# ============================================================

class BooksController < ApplicationController
  # =======================
  # 一覧
  # =======================
  def index
    @books = Book
      .select(:id, :title, :description, :updated_at, :book_sections_count)
      .includes(:book_sections)                # N+1回避
      .order(position: :asc, updated_at: :desc)
      .page(params[:page])
  end

  # =======================
  # 詳細
  # =======================
  def show
    @book = Book.includes(:book_sections).find(params[:id])
    @sections = @book.book_sections           # order(:position) 既定
  end
end
