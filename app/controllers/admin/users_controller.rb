class Admin::UsersController < Admin::BaseController
  layout "admin"

  before_action :set_user, only: [ :toggle_editor, :toggle_ban, :destroy ]

  def index
    @q = params[:q]
    @filter = params[:filter]

    @users = User.search(@q)
                 .yield_self { |u| @filter == "editors" ? u.editors : u }
                 .yield_self { |u| @filter == "banned" ? u.banned : u }
                 .order(created_at: :desc)
                 .page(params[:page]).per(50)
  end

  def toggle_editor
    return redirect_back fallback_location: admin_users_path, alert: "管理者は変更不可" if @user.admin?
    @user.toggle_editor!
    redirect_back fallback_location: admin_users_path, notice: "編集者権限を更新しました"
  end

  def toggle_ban
    return redirect_back fallback_location: admin_users_path, alert: "管理者は凍結不可" if @user.admin?
    @user.toggle_ban!(params[:ban_reason])
    redirect_back fallback_location: admin_users_path, notice: "ユーザー状態を更新しました"
  end

  def destroy
    return redirect_back fallback_location: admin_users_path, alert: "管理者は削除不可" if @user.admin?
    @user.destroy!
    redirect_to admin_users_path, notice: "ユーザーを削除しました"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
