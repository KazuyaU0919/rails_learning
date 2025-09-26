# app/controllers/searches_controller.rb
class SearchesController < ApplicationController
  # 未ログインでもOK
  def suggest
    q = params[:q].to_s.strip
    return render json: { items: [], q: q } if q.blank?

    # 前方一致（ILIKE prefix%）＋人気セカンダリ
    rel = PreCode
            .select(:id, :title, :description, :like_count, :use_count, :created_at)
            .where("title ILIKE ? OR description ILIKE ?", "#{q}%", "#{q}%")
            .order(like_count: :desc, use_count: :desc, created_at: :desc)
            .limit(24) # 一旦多めに取ってから 8 件に整形

    qi = q.downcase
    items = []

    rel.each do |pc|
      if pc.title.present? && pc.title.downcase.start_with?(qi)
        items << { type: "title", label: pc.title,
                    highlighted: highlight(pc.title, q), query: pc.title }
      end
      if pc.description.present? && pc.description.downcase.start_with?(qi)
        # 先頭語だけを検索語に使う（説明全体は長すぎるため）
        first_token =
          pc.description.to_s.split(/[\s 、。，．,。]/).first.presence || q
        items << { type: "desc", label: pc.description.truncate(80),
                    highlighted: highlight(pc.description, q, 80), query: first_token }
      end
      break if items.size >= 8
    end

    render json: { items:, q: q }
  end

  private

  # マッチ箇所を <b> で強調（大小無視）
  def highlight(text, q, limit = nil)
    t = limit ? text.truncate(limit) : text
    t.gsub(/(#{Regexp.escape(q)})/i, '<b>\1</b>')
  end
end
