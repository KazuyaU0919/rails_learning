# ============================================================
# Service: BookSections::Renumber
# ------------------------------------------------------------
# 目的:
# - Book に紐づく BookSection の position を 1..N に連番で振り直す
# 注意:
# - update_columns を使って validation / callback を回さずに高速更新
# - 既に正しい場合はスキップして無駄な更新を避ける
# ============================================================
class BookSections::Renumber
  # =======================
  # エントリポイント
  # -----------------------
  # 引数:
  #   book : Book インスタンス
  # 戻り値:
  #   なし（副作用で position を更新）
  # =======================
  def self.call(book)
    book.book_sections.order(:position).each_with_index do |s, idx|
      s.update_columns(position: idx + 1) if s.position != idx + 1
    end
  end
end
