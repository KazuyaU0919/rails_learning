# app/controllers/admin/sessions_controller.rb
class Admin::SessionsController < ApplicationController
  layout "admin"

  def new; end

  def create
    user = User.find_by(email: params[:email])

    if user&.admin? && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to admin_root_path, notice: "管理ログインしました"
    else
      flash.now[:alert] = "メールかパスワードが不正、または権限がありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end
end
