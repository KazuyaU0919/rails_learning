# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
  # new/create は未ログイン専用。edit/update は “トークン保持者” ならログイン有無に関係なくアクセス可
  before_action :require_guest!, only: %i[new create]
  before_action :use_gray_bg

  def new; end

  def create
    # 通常ユーザー向け（外部連携なし）の「パスワードを忘れた」導線
    user = User.where.missing(:authentications).find_by(email: params[:email])
    if user
      user.generate_reset_token!
      UserMailer.reset_password(user).deliver_later
    end
    redirect_to root_path, notice: "該当メールへパスワード再設定用のメールを送信しました（該当メールが存在する場合）"
  end

  def edit
    @user = User.find_by(reset_password_token: params[:id]) # :id = token
    unless @user&.reset_token_valid?
      redirect_to new_password_reset_path, alert: "トークンが無効です"
    end
  end

  def update
    @user = User.find_by(reset_password_token: params[:id])
    unless @user&.reset_token_valid?
      return redirect_to new_password_reset_path, alert: "トークンが無効です"
    end

    # トークン保持者なら（外部認証含め）誰でも更新可
    if @user.update(password_params)
      @user.clear_reset_token!
      @user.revoke_all_remember!
      cookies.delete(:remember_me, same_site: :lax, secure: Rails.env.production?)
      reset_session
      redirect_to new_session_path, notice: "パスワードを更新しました。ログインしてください"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def use_gray_bg
    @body_bg = "bg-slate-50"
  end
end
