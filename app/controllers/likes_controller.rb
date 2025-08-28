# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: [ :create, :destroy ]

  def create
    return head :forbidden if @pre_code.user_id == current_user.id

    current_user.likes.create!(pre_code: @pre_code)

    @pre_code.reload
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
    like.destroy!

    @pre_code.reload
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  end

  private

  def set_pre_code
    @pre_code =
      if params[:pre_code_id].present?
        PreCode.find(params[:pre_code_id])
      else
        # destroy 時は :id から like をたどるケースもあるため保険
        current_user.likes.find(params[:id]).pre_code
      end
  end
end
