# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  before_action :require_guest!,  only: %i[new create]
  before_action :require_login!,  only: %i[destroy]
  before_action :use_gray_bg

  def new; end

  def create
    email    = params[:email].to_s.strip.downcase
    password = params[:password].to_s

    user = User.find_by(email: email)

    if user&.banned?
      flash.now[:alert] = "このアカウントは凍結されています"
      return render :new, status: :forbidden
    end

    # 外部連携の有無に関係なく、パスワードがDBに存在し認証が通ればログイン可
    if user&.has_password? && user.authenticate(password)
      reset_session
      session[:user_id] = user.id
      user.update_column(:last_login_at, Time.current)
      remember_if_needed!(user)
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールまたはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_user&.forget!
    cookies.delete(:remember_me, same_site: :lax, secure: Rails.env.production?)
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end

  private

  def use_gray_bg
    @body_bg = "bg-slate-50"
  end

  def remember_if_needed!(user)
    return unless params[:remember_me] == "1"

    token = user.remember!
    cookies.encrypted[:remember_me] = {
      value:     { user_id: user.id, token: token },
      expires:   30.days,
      httponly:  true,
      secure:    Rails.env.production?,
      same_site: :lax
    }
  end
end
