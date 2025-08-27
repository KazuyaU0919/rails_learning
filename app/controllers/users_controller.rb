# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :require_guest!, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params) # provider なし → 通常登録

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "登録しました"
    else
      # モデル側に uniqueness が無い場合でも、実在チェックで拾う
      if email_taken_for_normal_signup?(@user)
        redirect_to new_session_path, alert: "そのメールアドレスは既に登録済みです。ログインしてください。"
      else
        flash.now[:alert] = "入力内容を確認してください"
        render :new, status: :unprocessable_entity
      end
    end

  rescue ActiveRecord::RecordNotUnique
    # DBレベルの競合も同じメッセージに統一
    redirect_to new_session_path, alert: "そのメールアドレスは既に登録済みです。ログインしてください。"
  end

  private

  def user_params
    params.require(:user)
          .permit(:name, :email, :password, :password_confirmation)
  end

  def email_taken_for_normal_signup?(user)
    # モデル側 uniqueness が付いていればまずここで true になる
    return true if user.errors.added?(:email, :taken)

    email = user.email.to_s.downcase
    User.where("lower(email) = ?", email).exists?
  end
end
