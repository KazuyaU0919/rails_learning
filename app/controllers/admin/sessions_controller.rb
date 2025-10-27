# app/controllers/admin/sessions_controller.rb
# ============================================================
# 管理: セッション（管理者ログイン）
# ------------------------------------------------------------
# ・管理画面専用のログイン/ログアウト
# ・admin? なユーザーのみログインを許可
# ・一般ログインとはルーティング/画面を分離
# ============================================================
class Admin::SessionsController < ApplicationController
  layout "admin"

  # =======================
  # アクション
  # =======================
  def new; end

  def create
    user = User.find_by(email: params[:email])

    # admin 権限 + パスワード一致 が必須
    if user&.admin? && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to admin_root_path, notice: "管理ログインしました"
    else
      flash.now[:alert] = "メールかパスワードが不正、または権限がありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end
end
