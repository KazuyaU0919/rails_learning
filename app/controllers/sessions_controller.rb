class SessionsController < ApplicationController
  before_action :require_guest!,  only: %i[new create]
  before_action :require_login!,  only: %i[destroy]
  before_action :use_gray_bg

  def new; end

  def create
    user = User.find_by(email: params[:email])

    # 通常ログイン：外部連携アカウント（authenticationsあり）はパスワード不要/不可
    if user&.uses_password? && user&.authenticate(params[:password])
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

  private

  def use_gray_bg
    @body_bg = "bg-slate-50"
  end
end
