# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  def require_admin!
    # ログインしていない or admin:false → 入口で閉め出す
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者のみアクセス可能です"
    end
  end
end
