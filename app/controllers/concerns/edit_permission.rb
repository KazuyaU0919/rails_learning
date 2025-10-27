# ============================================================
# EditPermission（Concern）
# ------------------------------------------------------------
# 編集権限を共通で扱うためのモジュール。
# - current_user.admin? または user.can_edit?(record)
#   により編集可否を判定。
# - ビューでも can_edit? を使えるように helper_method に登録。
# ============================================================

module EditPermission
  extend ActiveSupport::Concern

  included do
    helper_method :can_edit?
  end

  # =======================
  # 編集可能判定
  # =======================
  def can_edit?(record)
    return false unless current_user
    current_user.admin? || current_user.can_edit?(record)
  end

  # =======================
  # 編集権限の強制チェック
  # =======================
  def require_edit_permission!(record)
    return true if can_edit?(record)
    redirect_back fallback_location: root_path, alert: "編集権限がありません"
    false
  end
end
