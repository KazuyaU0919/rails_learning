# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  before_action :require_guest!, only: %i[new create]
  before_action :require_login!, only: %i[destroy]
  before_action :use_gray_bg

  def new; end

  def create
    user = User.find_by(email: params[:email])

    # ユーザーが存在する場合のみBANチェック
    if user&.banned?
      flash.now[:alert] = "このアカウントは凍結されています"
      render :new, status: :forbidden
      return
    end

    # 通常ログイン：外部連携アカウント(authenticationsあり)はパスワード不要
    if user&.uses_password? && user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      user.update_column(:last_login_at, Time.current)
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

  private

  def use_gray_bg
    @body_bg = "bg-slate-50"
  end
end
