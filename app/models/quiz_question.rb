# app/models/quiz_question.rb
class QuizQuestion < ApplicationRecord
  has_paper_trail
  belongs_to :quiz
  belongs_to :quiz_section

  with_options presence: true do
    validates :question,    length: { maximum: 2_000 }
    validates :explanation, length: { maximum: 2_000 }
    validates :choice1,     length: { maximum: 100 }
    validates :choice2,     length: { maximum: 100 }
    validates :choice3,     length: { maximum: 100 }
    validates :choice4,     length: { maximum: 100 }
  end

  validates :correct_choice, presence: true, inclusion: { in: 1..4 }
  validates :position,
           presence: true,
           numericality: {
             only_integer: true,
             greater_than: 0,
             less_than_or_equal_to: 9_999
           }

  # 編集権限チェック
  def editable_attributes
    %i[question choice1 choice2 choice3 choice4 correct_choice explanation]
  end
end
