# app/controllers/used_codes_controller.rb
class UsedCodesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: :create

  def create
    # 自分の投稿は弾く
    return head :forbidden if @pre_code.user_id == current_user.id

    # ---- 連打の簡易スロットル（同一ユーザーが短時間に連投したら無視）----
    recently = UsedCode
      .where(user: current_user, pre_code: @pre_code)
      .where("created_at > ?", 3.seconds.ago)
      .exists?

    unless recently
      # レコードを1件作るだけで counter_cache(:use_count) が +1 される
      UsedCode.create!(user: current_user, pre_code: @pre_code, used_at: Time.current)
    end

    # 最新値を再読込
    @pre_code.reload

    # 同期リダイレクト（パラメータで来ていればエディタ、無ければ一覧）
    redirect_to params[:redirect].presence || code_libraries_path
  end

  private

  def set_pre_code
    @pre_code = PreCode.find(params[:pre_code_id])
  end
end
