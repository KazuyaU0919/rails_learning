# app/models/quiz_question.rb
class QuizQuestion < ApplicationRecord
  has_paper_trail
  belongs_to :quiz
  belongs_to :quiz_section

  validates :question, :explanation, presence: true
  with_options presence: true do
    validates :choice1
    validates :choice2
    validates :choice3
    validates :choice4
  end
  validates :correct_choice, presence: true, inclusion: { in: 1..4 }
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  # 編集権限チェック
  def editable_attributes
    %i[question choice1 choice2 choice3 choice4 correct_choice explanation]
  end
end
