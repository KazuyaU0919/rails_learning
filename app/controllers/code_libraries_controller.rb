class CodeLibrariesController < ApplicationController
  before_action :set_pre_code, only: :show

  def index
    base = PreCode.except_user(current_user&.id)
    @q = base.ransack(params[:q])

    # 検索結果
    rel = @q.result

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

    @pre_codes = rel.includes(:user).page(params[:page])
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
end
