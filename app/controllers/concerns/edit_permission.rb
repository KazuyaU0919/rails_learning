# app/controllers/concerns/edit_permission.rb
module EditPermission
  extend ActiveSupport::Concern

  included do
    helper_method :can_edit?
  end

  def can_edit?(record)
    return false unless current_user
    current_user.admin? || current_user.can_edit?(record)
  end

  def require_edit_permission!(record)
    return true if can_edit?(record)
    redirect_back fallback_location: root_path, alert: "編集権限がありません"
    false
  end
end
