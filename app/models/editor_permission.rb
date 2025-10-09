# app/models/editor_permission.rb
class EditorPermission < ApplicationRecord
  belongs_to :user

  VALID_TARGET_TYPES = %w[BookSection QuizQuestion].freeze
  enum :role, { sub_editor: 0 }, prefix: true

  validates :target_type, presence: true, inclusion: { in: VALID_TARGET_TYPES }
  validates :target_id,   presence: true, numericality: { only_integer: true }
  # ※ 厳格存在チェックはスペックがソフト参照を期待しているため外す
  # validate  :target_must_exist

  # ---- 表示用ヘルパ ----
  def target_record
    return nil if target_type.blank? || target_id.blank?
    return nil unless VALID_TARGET_TYPES.include?(target_type)
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

  # 厳格存在チェック（必要になったら環境で有効化して使う）
  # private
  # def target_must_exist
  #   return if target_type.blank? || target_id.blank?
  #   return unless VALID_TARGET_TYPES.include?(target_type)
  #   errors.add(:target_id, :not_found) unless target_type.constantize.exists?(id: target_id)
  # rescue NameError
  #   errors.add(:target_type, :invalid)
  # end
end
