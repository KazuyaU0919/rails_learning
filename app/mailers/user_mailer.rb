class UserMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    @url  = edit_password_reset_url(@user.reset_password_token) # トークンを path param で
    mail to: @user.email, subject: "パスワード再設定のご案内"
  end
end
