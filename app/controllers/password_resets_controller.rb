# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
  before_action :require_guest!, only: %i[new create edit update]
  before_action :use_gray_bg

  def new; end

  def create
    # 通常ログインユーザーのみ対象（provider が空）
    if (user = User.find_by(email: params[:email], provider: nil))
      user.generate_reset_token!
      UserMailer.reset_password(user).deliver_later
    end
    redirect_to root_path, notice: "再設定用メールを送信しました（該当メールが存在する場合）"
  end

  def edit
    @user = User.find_by(reset_password_token: params[:id]) # :id = token
    redirect_to new_password_reset_path, alert: "トークンが無効です" unless @user&.reset_token_valid?
  end

  def update
    @user = User.find_by(reset_password_token: params[:id])
    return redirect_to new_password_reset_path, alert: "トークンが無効です" unless @user&.reset_token_valid?

    # 通常ユーザーとして更新（外部ログインは対象外）
    if @user.update(password_params.merge(provider: nil))
      @user.clear_reset_token!
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
