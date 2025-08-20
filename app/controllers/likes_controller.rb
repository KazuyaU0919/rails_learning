# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :require_login!

  def create
    @pre_code = PreCode.find(params[:pre_code_id])
    Like.create!(user: current_user, pre_code: @pre_code)

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  rescue ActiveRecord::RecordInvalid
    head :ok
  end

  def destroy
    like = current_user.likes.find(params[:id])
    @pre_code = like.pre_code
    like.destroy
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  end
end
