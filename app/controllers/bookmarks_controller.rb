# app/controllers/bookmarks_controller.rb
class BookmarksController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: :create

  def create
    return head :forbidden if @pre_code.user_id == current_user.id

    if current_user.bookmarks.count >= 300
      redirect_back fallback_location: code_libraries_path,
                    alert: I18n.t("bookmarks.limit_reached") and return
    end

    current_user.bookmarks.create!(pre_code: @pre_code)
    @pre_code.reload
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  rescue ActiveRecord::RecordInvalid
    head :ok
  end

  def destroy
    bookmark = current_user.bookmarks.find(params[:id])
    @pre_code = bookmark.pre_code
    bookmark.destroy!
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
