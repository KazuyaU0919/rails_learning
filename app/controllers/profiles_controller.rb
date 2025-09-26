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
        redirect_to profile_path, notice: "パスワードを更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    else
      head :bad_request
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
