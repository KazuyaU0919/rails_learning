# app/controllers/used_codes_controller.rb
class UsedCodesController < ApplicationController
  before_action :require_login!

  def create
    @pre_code = PreCode.find(params[:pre_code_id])
    UsedCode.find_or_create_by!(user: current_user, pre_code: @pre_code) do |uc|
      uc.used_at = Time.current
    end

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  end
end
