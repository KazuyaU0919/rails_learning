# ============================================================
# Book
# ------------------------------------------------------------
# コンテンツ「書籍」のメタ情報（タイトル、説明、表示順など）を表す。
# 子として複数の BookSection を持つ。
# ============================================================

class Book < ApplicationRecord
  # =======================
  # 関連
  # =======================
  has_many :book_sections, -> { order(:position) }, dependent: :destroy

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
           },
           uniqueness: true

  # =======================
  # コールバック
  # =======================
  before_validation :set_default_position, on: :create

  # =======================
  # Ransack 許可
  # =======================
  def self.ransackable_attributes(_auth = nil)
    %w[title]
  end

  def self.ransackable_associations(_auth = nil)
    %w[book_sections]
  end

  private

  # 連番付与（最大position+1）
  def set_default_position
    self.position ||= (Book.maximum(:position) || 0) + 1
  end
end
