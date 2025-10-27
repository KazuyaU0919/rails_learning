# ============================================================
# Helper: 管理 > Users
# ------------------------------------------------------------
# ユーザーの役割(role)を表すラベルを装飾バッジとして生成。
# ============================================================
module Admin::UsersHelper

  # =======================
  # ユーザー権限バッジ
  # -----------------------
  # role に応じて色と文言を変更。
  #   :admin      → 金色
  #   :editor     → 紫
  #   :sub_editor → 青
  #   :一般       → グレー
  # =======================
  def role_badge_for(user)
    role = user.effective_role
    label, cls =
      case role
      when :admin      then [ "管理者",  "bg-amber-50 text-amber-700 ring-amber-200" ]
      when :editor     then [ "編集者",  "bg-indigo-50 text-indigo-700 ring-indigo-200" ]
      when :sub_editor then [ "sub_editor", "bg-sky-50 text-sky-700 ring-sky-200" ]
      else                  [ "一般",    "bg-slate-50 text-slate-600 ring-slate-200" ]
      end

    %(<span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset #{cls}">#{h label}</span>).html_safe
  end
end
