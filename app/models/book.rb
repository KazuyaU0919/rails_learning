# app/models/book.rb
class Book < ApplicationRecord
  has_many :book_sections, -> { order(:position) }, dependent: :destroy

  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 500 }

  # 並び順
  validates :position,
           presence: true,
           numericality: { only_integer: true, greater_than: 0 },
           uniqueness: true   # 重複時にエラー表示（DBのuniqueと二重で守る）

  before_validation :set_default_position, on: :create

  private

  def set_default_position
    self.position ||= (Book.maximum(:position) || 0) + 1
  end
end
