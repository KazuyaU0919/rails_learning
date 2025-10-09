# app/models/quiz.rb
class Quiz < ApplicationRecord
  has_many :quiz_sections, -> { order(:position) }, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy

  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :position,
           presence: true,
           numericality: {
             only_integer: true,
             greater_than: 0,
             less_than_or_equal_to: 9_999
           }

  before_validation :set_default_position, on: :create

  private

  def set_default_position
    self.position ||= (Quiz.maximum(:position) || 0) + 1
  end
end
