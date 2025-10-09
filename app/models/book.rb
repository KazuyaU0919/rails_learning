# app/models/book.rb
class Book < ApplicationRecord
  has_many :book_sections, -> { order(:position) }, dependent: :destroy

  # タイトル100 / 説明1000 / 並び順は 1..9999 かつ一意
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

  before_validation :set_default_position, on: :create

  private

  def set_default_position
    self.position ||= (Book.maximum(:position) || 0) + 1
  end
end
