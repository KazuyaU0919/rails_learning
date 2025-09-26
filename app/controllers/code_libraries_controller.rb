class CodeLibrariesController < ApplicationController
  before_action :set_pre_code, only: :show

  def index
    base = PreCode.except_user(current_user&.id)

    # --- タグ AND フィルタ（サブクエリで ID のみ絞る） ---
    if params[:tags].present?
      tag_keys  = parse_tags(params[:tags])                         # "ruby,array" or ["ruby","array"]
      norm_keys = tag_keys.map { |n| normalize_tag(n) }.uniq

      if norm_keys.any?
        tag_ids = Tag.where(name_norm: norm_keys).pluck(:id)

        if tag_ids.any?
          tagged_ids = PreCode.joins(:tags)
                               .where(tags: { id: tag_ids })
                               .group("pre_codes.id")
                               .having("COUNT(DISTINCT tags.id) = ?", tag_ids.size)
                               .select(:id)
          base = base.where(id: tagged_ids)
        else
          base = base.none
        end
      end
    end

    @q = base.ransack(params[:q])

    # 検索結果
    rel = @q.result

    # --- ブックマーク絞り込み ---
    if params[:only_bookmarked].present? && logged_in?
      rel = rel.joins(:bookmarks).where(bookmarks: { user_id: current_user.id })
    end

    # ソートキー（popular / used / newest）。デフォルト popular
    sort_key = params[:sort].presence || "popular"
    rel =
      case sort_key
      when "used"
        rel.order(use_count: :desc).order(like_count: :desc).order(created_at: :desc)
      when "newest"
        rel.order(created_at: :desc).order(like_count: :desc).order(use_count: :desc)
      else # "popular"
        rel.order(like_count: :desc).order(use_count: :desc).order(created_at: :desc)
      end

    # JOIN にせず別クエリで読み込む（GROUP BY と競合しない）
    @pre_codes = rel.preload(:user, :tags).page(params[:page])
  end

  def show
    if logged_in? && @pre_code.user_id == current_user.id
      redirect_to pre_codes_path, alert: "自分のデータです" and return
    end
  end

  private

  def set_pre_code
    @pre_code = PreCode.find(params[:id])
  end

  # "ruby,array" / ["ruby","array"] を配列に整形
  def parse_tags(val)
    Array(val).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
  end

  # Tag.normalize があれば使用、なければ簡易正規化
  def normalize_tag(name)
    if Tag.respond_to?(:normalize)
      Tag.normalize(name)
    else
      name.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " ")
    end
  end
end
