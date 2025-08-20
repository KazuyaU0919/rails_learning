class CodeLibrariesController < ApplicationController
  before_action :set_pre_code, only: :show

  def index
    # params: q(キーワード), sort(popular|used), page
    scope = PreCode.all
    scope = scope.except_user(current_user.id) if current_user # 自分の投稿を除外
    scope = scope.keyword(params[:q])

    case params[:sort]
    when "used" then scope = scope.most_used
    else             scope = scope.popular # デフォルト: 人気順
    end

    @pre_codes = scope.includes(:user).page(params[:page])
  end

  def show
    if current_user && @pre_code.user_id == current_user.id
      redirect_to pre_codes_path, alert: "自分のデータです" and return
    end
  end

  private

  def set_pre_code
    @pre_code = PreCode.find(params[:id])
  end
end
