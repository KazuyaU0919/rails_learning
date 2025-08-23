# app/models/book.rb
class Book < ApplicationRecord
  has_many :book_sections, -> { order(:position) }, dependent: :destroy

  validates :title,       presence: true, length: { maximum: 100 }
  validates :description, presence: true, length: { maximum: 500 }
end
