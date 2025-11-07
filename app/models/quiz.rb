# ============================================================
# Quiz
# ------------------------------------------------------------
# クイズのメタ情報を表すモデル。セクション/問題を複数持つ。
# 表示順は作成時に連番で自動付与。
# ============================================================

class Quiz < ApplicationRecord
  # =======================
  # 関連
  # =======================
  has_many :quiz_sections, -> { order(:position) }, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy

  # =======================
  # バリデーション
  # =======================
  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 1000 }
  validates :position,
           presence: true,
           numericality: {
             only_integer: true,
             greater_than: 0,
             less_than_or_equal_to: 9_999
           }

  # =======================
  # コールバック
  # =======================
  before_validation :set_default_position, on: :create

  # =======================
  # Ransack 設定（検索許可）
  # -----------------------
  # 管理画面の検索で許可する属性/関連をホワイトリスト化
  # =======================
  def self.ransackable_attributes(_auth = nil)
    %w[title]
  end

  def self.ransackable_associations(_auth = nil)
    %w[quiz_sections quiz_questions]
  end

  private

  # 連番付与（最大position+1）
  def set_default_position
    self.position ||= (Quiz.maximum(:position) || 0) + 1
  end
end
