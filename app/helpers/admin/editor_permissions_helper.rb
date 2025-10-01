# app/helpers/admin/editor_permissions_helper.rb
module Admin::EditorPermissionsHelper
  def role_badge(role)
    %(<span class="px-2 py-0.5 rounded text-xs bg-indigo-100 text-indigo-700">#{h role}</span>).html_safe
  end

  def type_badge(type)
    %(<span class="px-2 py-0.5 rounded text-xs bg-slate-100 text-slate-700">#{h type}</span>).html_safe
  end

  def target_preview_text(type, id)
    return "" if type.blank? || id.blank?
    begin
      label = case type
      when "BookSection"
        if (rec = BookSection.find_by(id: id))
          book = rec.try(:book)&.title
          sec  = rec.try(:heading) || rec.try(:title)
          [ "BookSection##{id}", [ book, sec ].compact.join(" / ") ].reject(&:blank?).join(" — ")
        end
      when "QuizQuestion"
        if (rec = QuizQuestion.find_by(id: id))
          quiz = rec.try(:quiz)&.title
          sect = rec.try(:quiz_section)&.heading
          qpos = rec.try(:position)
          [ "QuizQuestion##{id}", [ quiz, sect, ("Q#{qpos}" if qpos) ].compact.join(" / ") ].reject(&:blank?).join(" — ")
        end
      end
      label.presence || "#{type}##{id}（見つかりません）"
    rescue
      "#{type}##{id}"
    end
  end
end
