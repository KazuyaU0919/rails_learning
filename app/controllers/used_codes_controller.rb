# app/controllers/used_codes_controller.rb
class UsedCodesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: :create

  def create
    # 自分の投稿は弾く
    return head :forbidden if @pre_code.user_id == current_user.id

    # 1ユーザー1レコード
    UsedCode.find_or_create_by!(user: current_user, pre_code: @pre_code) do |uc|
      uc.used_at = Time.current
    end

    # 表示用に最新値へリロード
    @pre_code.reload

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  end

  private

  def set_pre_code
    @pre_code = PreCode.find(params[:pre_code_id])
  end
end
