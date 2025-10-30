# ============================================================
# QuizQuestion
# ------------------------------------------------------------
# クイズの各問題を表すモデル。選択肢4つ＋正解番号、解説、並び順を持つ。
# 変更は PaperTrail で履歴管理。
# ============================================================

class QuizQuestion < ApplicationRecord
  # =======================
  # 関連
  # =======================
  belongs_to :quiz
  belongs_to :quiz_section

  # PaperTrail（変更履歴）
  has_paper_trail

  # =======================
  # バリデーション
  # =======================
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

  # =======================
  # 編集権限（編集可能カラム）
  # =======================
  def editable_attributes
    %i[question choice1 choice2 choice3 choice4 correct_choice explanation]
  end
end
