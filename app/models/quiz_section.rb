# app/models/quiz_section.rb
class QuizSection < ApplicationRecord
  belongs_to :quiz, touch: true
  belongs_to :book_section, optional: true
  has_many :quiz_questions, -> { order(:position) }, dependent: :destroy

  validates :heading,  presence: true, length: { maximum: 100 }
  validates :position,
           presence: true,
           numericality: {
             only_integer: true,
             greater_than: 0,
             less_than_or_equal_to: 9_999
           }
  validates :is_free, inclusion: { in: [ true, false ] }

  scope :free, -> { where(is_free: true) }
  scope :paid, -> { where(is_free: false) }

  # 前後ナビ（同一 quiz 内）
  def previous = quiz.quiz_sections.where("position < ?", position).order(position: :desc).first
  def next     = quiz.quiz_sections.where("position > ?", position).order(position: :asc).first
end
