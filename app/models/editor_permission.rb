# app/models/editor_permission.rb
class EditorPermission < ApplicationRecord
  belongs_to :user

  # このモデルで許可する対象タイプ（ホワイトリスト）
  VALID_TARGET_TYPES = %w[BookSection QuizQuestion].freeze

  # sub_editor のみ（サイト全体編集は users.editor を使う）
  enum :role, { sub_editor: 0 }, prefix: true

  validates :target_type, presence: true, inclusion: { in: VALID_TARGET_TYPES }
  validates :target_id,   presence: true, numericality: { only_integer: true }

  # ---- 表示用ヘルパ（モデル側でも呼べるように） ----
  def target_record
    return nil if target_type.blank? || target_id.blank?
    return nil unless VALID_TARGET_TYPES.include?(target_type)

    # ここは constantize の前にホワイトリストで必ず絞り込む
    target_type.constantize.find_by(id: target_id)
  rescue NameError
    nil
  end

  def target_human_label
    rec  = target_record
    base = "#{target_type}##{target_id}"
    return base unless rec

    case rec
    when defined?(BookSection) && BookSection
      book_title = rec.respond_to?(:book) ? rec.book&.title : nil
      sec_title  = rec.try(:heading) || rec.try(:title)
      [ base, [ book_title, sec_title ].compact.join(" / ") ].reject(&:blank?).join(" — ")
    when defined?(QuizQuestion) && QuizQuestion
      quiz_title = rec.try(:quiz)&.title
      section_h  = rec.try(:quiz_section)&.heading
      qpos       = rec.try(:position)
      tail = [ quiz_title, section_h, ("Q#{qpos}" if qpos) ].compact.join(" / ")
      [ base, tail ].reject(&:blank?).join(" — ")
    else
      base
    end
  end
end
