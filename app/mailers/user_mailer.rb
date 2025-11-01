# ============================================================
# Mailer: UserMailer
# ------------------------------------------------------------
# ユーザー向けメール。
# - reset_password: パスワード再設定メール
# ============================================================
class UserMailer < ApplicationMailer
  # =======================
  # パスワード再設定の案内
  # -----------------------
  # 引数:
  #   user: 再設定トークンを持つユーザー
  # ビューでは @user, @url を使用
  # =======================
  def reset_password(user)
    @user = user
    @url  = edit_password_reset_url(@user.reset_password_token)
    mail to: @user.email, subject: "パスワード再設定のご案内"
  end
end
