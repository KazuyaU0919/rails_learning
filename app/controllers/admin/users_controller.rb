# ============================================================
# 管理: ユーザー (User)
# ------------------------------------------------------------
# ・一覧検索 + 絞り込み（編集者 / 凍結）
# ・権限トグル（toggle_editor / toggle_ban）
# ・管理者は安全のため変更不可
# ============================================================
class Admin::UsersController < Admin::BaseController
  layout "admin"
  before_action :set_user, only: [ :toggle_editor, :toggle_ban, :destroy ]

  # =======================
  # 一覧
  # =======================
  def index
    @q = params[:q]
    @filter = params[:filter]

    users = User.all
    if @q.present?
      if @q.to_s =~ /\A\d+\z/
        users = users.where(id: @q.to_i)
      else
        users = users.search(@q)
      end
    end

    @users = users
               .yield_self { |u| @filter == "editors" ? u.editors : u }
               .yield_self { |u| @filter == "banned"  ? u.banned  : u }
               .includes(:editor_permissions)
               .order(created_at: :desc)
               .page(params[:page]).per(50)
  end

  # =======================
  # 編集者権限トグル
  # =======================
  def toggle_editor
    return redirect_back fallback_location: admin_users_path, alert: "管理者は変更不可" if @user.admin?
    @user.toggle_editor!
    redirect_back fallback_location: admin_users_path, notice: "編集者権限を更新しました"
  end

  # =======================
  # 凍結トグル
  # =======================
  def toggle_ban
    return redirect_back fallback_location: admin_users_path, alert: "管理者は凍結不可" if @user.admin?
    @user.toggle_ban!(params[:ban_reason])
    redirect_back fallback_location: admin_users_path, notice: "ユーザー状態を更新しました"
  end

  # =======================
  # 削除
  # =======================
  def destroy
    return redirect_back fallback_location: admin_users_path, alert: "管理者は削除不可" if @user.admin?
    @user.destroy!
    redirect_to admin_users_path, notice: "ユーザーを削除しました"
  end

  private

  # =======================
  # 共通セットアップ
  # =======================
  def set_user
    @user = User.find(params[:id])
  end
end
