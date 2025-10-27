# ============================================================
# Helper: 管理 > EditorPermissions
# ------------------------------------------------------------
# 管理者が設定する「編集権限」の表示を補助する。
# - 権限(role/type)バッジのHTML生成
# - 対象(BookSection/QuizQuestion)のプレビュー文字列生成
# ============================================================
module Admin::EditorPermissionsHelper

  # =======================
  # 権限ロールのバッジ表示
  # -----------------------
  # 例: <%= role_badge("Editor") %>
  # =======================
  def role_badge(role)
    %(<span class="px-2 py-0.5 rounded text-xs bg-indigo-100 text-indigo-700">#{h role}</span>).html_safe
  end

  # =======================
  # 権限タイプのバッジ表示
  # -----------------------
  # 例: <%= type_badge("BookSection") %>
  # =======================
  def type_badge(type)
    %(<span class="px-2 py-0.5 rounded text-xs bg-slate-100 text-slate-700">#{h type}</span>).html_safe
  end

  # =======================
  # 対象レコードのプレビュー文字列を生成
  # -----------------------
  # 引数:
  #   type : "BookSection" or "QuizQuestion"
  #   id   : 対象のレコードID
  # 例:
  #   "BookSection#12 — Rails入門 / モデル編"
  #   "QuizQuestion#45 — Ruby基礎 / Q3"
  # =======================
  def target_preview_text(type, id)
    return "" if type.blank? || id.blank?

    begin
      label =
        case type
        when "BookSection"
          if (rec = BookSection.find_by(id: id))
            book = rec.try(:book)&.title
            sec  = rec.try(:heading) || rec.try(:title)
            [ "BookSection##{id}", [book, sec].compact.join(" / ") ].reject(&:blank?).join(" — ")
          end

        when "QuizQuestion"
          if (rec = QuizQuestion.find_by(id: id))
            quiz = rec.try(:quiz)&.title
            sect = rec.try(:quiz_section)&.heading
            qpos = rec.try(:position)
            [ "QuizQuestion##{id}", [quiz, sect, ("Q#{qpos}" if qpos)].compact.join(" / ") ].reject(&:blank?).join(" — ")
          end
        end

      label.presence || "#{type}##{id}（見つかりません）"
    rescue
      "#{type}##{id}"
    end
  end
end
