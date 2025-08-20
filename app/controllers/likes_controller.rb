class LikesController < ApplicationController
  before_action :require_login!

  def create
    pre_code = PreCode.find(params[:pre_code_id])
    Like.create!(user: current_user, pre_code: pre_code) # 重複は model で弾く

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  rescue ActiveRecord::RecordInvalid
    head :ok
  end

  def destroy
    like = current_user.likes.find(params[:id]) # 自分の Like のみ削除可
    like.destroy

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  end
end
