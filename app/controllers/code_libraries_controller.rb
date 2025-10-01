class CodeLibrariesController < ApplicationController
  before_action :set_pre_code, only: :show

  def index
    base = PreCode.except_user(current_user&.id)

    # --- タグ AND フィルタ（サブクエリで ID のみ絞る） ---
    if params[:tags].present?
      tag_keys  = parse_tags(params[:tags])
      norm_keys = tag_keys.map { |n| normalize_tag(n) }.uniq

      if norm_keys.any?
        tag_ids = Tag.where(name_norm: norm_keys).pluck(:id)

        base =
          if tag_ids.any?
            # 選択されたタグを“すべて”持つ PreCode の id を抽出
            tagged_ids = PreCode.joins(:tags)
                                 .where(tags: { id: tag_ids })
                                 .group("pre_codes.id")
                                 .having("COUNT(DISTINCT tags.id) = ?", tag_ids.size)
                                 .select(:id)
            base.where(id: tagged_ids)
          else
            base.none
          end
      end
    end

    # キーワード検索
    @q = base.ransack(params[:q])
    rel = @q.result

    # --- ブックマークのみ表示（ログイン時） ---
    if params[:only_bookmarked].present? && logged_in?
      rel = rel.joins(:bookmarks).where(bookmarks: { user_id: current_user.id })
    end

    # 並び順（popular / used / newest）
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

    # N+1 対策（GROUP を避けるため JOIN ではなく preload）
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

  # === タグ文字列ユーティリティ ===
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
