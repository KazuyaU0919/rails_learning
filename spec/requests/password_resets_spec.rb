# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
  # だれでもアクセス可

  def new
  end

  # パスワード再設定メール送信
  def create
    email = params[:email].to_s.strip
    user  = User.find_by(email: email)

    # 現在の仕様: 外部ログインユーザー（authentications がある）は対象外
    if user && user.authentications.none?
      user.update!(
        reset_password_token:    SecureRandom.urlsafe_base64(32),
        reset_password_sent_at:  Time.current
      )
      PasswordResetMailer.reset(user).deliver_later
    end

    # 情報漏えい防止のため、存在有無に関わらず同じレスポンス
    redirect_to root_path
  end

  # トークン入力画面の表示
  def edit
    @user = find_user_by_token!(params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to new_password_reset_path, alert: I18n.t("password_resets.invalid_token", default: "トークンが無効です")
  end

  # パスワード更新
  def update
    @user = find_user_by_token!(params[:token])

    if token_expired?(@user)
      redirect_to new_password_reset_path, alert: I18n.t("password_resets.invalid_token", default: "トークンが無効です")
      return
    end

    if @user.update(user_params)
      # トークンは使い捨て
      @user.update!(reset_password_token: nil, reset_password_sent_at: nil)
      redirect_to new_session_path, notice: I18n.t("password_resets.updated", default: "パスワードを変更しました")
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to new_password_reset_path, alert: I18n.t("password_resets.invalid_token", default: "トークンが無効です")
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def find_user_by_token!(token)
    User.find_by!(reset_password_token: token)
  end

  def token_expired?(user)
    user.reset_password_sent_at.blank? || user.reset_password_sent_at < 30.minutes.ago
  end
end
