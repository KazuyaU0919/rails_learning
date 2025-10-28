# ============================================================
# Admin::BaseController
# ------------------------------------------------------------
# 管理画面用コントローラの基底クラス。
# - すべての Admin 名前空間配下で継承される。
# - 管理者（admin:true）でなければアクセス不可。
# ============================================================

class Admin::BaseController < ApplicationController
  before_action :require_admin!

  private

  # =======================
  # 管理者チェック
  # =======================
  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者のみアクセス可能です"
    end
  end
end
