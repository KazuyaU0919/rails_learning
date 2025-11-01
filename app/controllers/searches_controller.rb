# ============================================================
# SearchesController
# ------------------------------------------------------------
# 検索補完API（/search/suggest）を提供。
# ------------------------------------------------------------
# 主な責務：
#   - 入力中キーワードから PreCode タイトル・説明の先頭一致候補を返す
#   - 各候補を type/title/desc で分類
#   - 表示用に HTML強調付き文字列を生成
# ============================================================

class SearchesController < ApplicationController
  # =======================
  # サジェストAPI（未ログインOK）
  # =======================
  def suggest
    q = params[:q].to_s.strip
    return render json: { items: [], q: q } if q.blank?

    # 前方一致検索 + 人気順セカンダリソート
    rel = PreCode
            .select(:id, :title, :description, :like_count, :use_count, :created_at)
            .where("title ILIKE ? OR description ILIKE ?", "#{q}%", "#{q}%")
            .order(like_count: :desc, use_count: :desc, created_at: :desc)
            .limit(24)

    qi = q.downcase
    items = []

    rel.each do |pc|
      # --- titleマッチ ---
      if pc.title.present? && pc.title.downcase.start_with?(qi)
        items << {
          type: "title", label: pc.title,
          highlighted: highlight(pc.title, q),
          query: pc.title
        }
      end

      # --- descriptionマッチ ---
      if pc.description.present? && pc.description.downcase.start_with?(qi)
        first_token = pc.description.to_s.split(/[\s 、。，．,。]/).first.presence || q
        items << {
          type: "desc", label: pc.description.truncate(80),
          highlighted: highlight(pc.description, q, 80),
          query: first_token
        }
      end

      break if items.size >= 8
    end

    render json: { items:, q: q }
  end

  private

  # =======================
  # 強調表示（<b>）
  # =======================
  def highlight(text, q, limit = nil)
    t = limit ? text.truncate(limit) : text
    t.gsub(/(#{Regexp.escape(q)})/i, '<b>\1</b>')
  end
end
