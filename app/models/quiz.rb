# app/models/quiz.rb
class Quiz < ApplicationRecord
  has_many :quiz_sections, -> { order(:position) }, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 500 }
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  before_validation :set_default_position, on: :create

  private

  def set_default_position
    self.position ||= (Quiz.maximum(:position) || 0) + 1
  end
end
