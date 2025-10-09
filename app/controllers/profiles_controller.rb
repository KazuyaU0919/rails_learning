# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :require_login!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    case params[:commit]
    when "プロフィール更新"
      if @user.update(profile_params)
        redirect_to profile_path, notice: "プロフィールを更新しました"
      else
        render :edit, status: :unprocessable_entity
      end

    when "パスワード更新"
      unless @user.authenticate(params.dig(:user, :current_password).to_s)
        @user.errors.add(:current_password, "現在のパスワードが違います")
        flash.now[:alert] = "現在のパスワードが違います"
        return render :edit, status: :unprocessable_entity
      end
      if @user.update(password_params)
        @user.revoke_all_remember!
        cookies.delete(:remember_me, same_site: :lax, secure: Rails.env.production?)
        redirect_to profile_path, notice: "パスワードを更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    else
      head :bad_request
    end
  end

  # パスワード未設定ユーザー向け：新規作成メール送付
  def password_setup
    # すでにパスワードがあるなら弾く
    if current_user.uses_password?
      return redirect_to edit_profile_path, alert: "あなたのアカウントには、すでにパスワードが存在します"
    end

    email = params[:email].to_s.strip.downcase
    if email.present? && email == current_user.email.to_s.downcase
      current_user.generate_reset_token!
      UserMailer.reset_password(current_user).deliver_later
      redirect_to edit_profile_path, notice: "登録メールアドレスにパスワード再設定メールを送信しました"
    else
      redirect_to edit_profile_path, alert: "メールアドレスが一致しません"
    end
  end

  def revoke_remember
    current_user.revoke_all_remember!
    redirect_to profile_path, notice: "他の端末のログイン状態をすべて解除しました"
  end

  private

  def profile_params
    params.require(:user).permit(:name)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
