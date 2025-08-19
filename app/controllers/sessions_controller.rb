# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  before_action :require_guest!,  only: %i[new create]
  before_action :require_login!,  only: %i[destroy]

  def new; end

  def create
    user = User.find_by(email: params[:email])

    # 通常ログイン（外部ログイン行は password を持たないので弾く）
    if user&.provider.blank? && user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールまたはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end
end
