# app/models/book_section.rb
class BookSection < ApplicationRecord
  belongs_to :book, counter_cache: true, touch: true
  has_many_attached :images

  validates :heading,  presence: true, length: { maximum: 100 }
  validates :content,  presence: true
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                       uniqueness: { scope: :book_id }

  # =======================
  # スコープ
  # =======================
  scope :free, -> { where(is_free: true) }   # 無料ページだけ抽出
  scope :paid, -> { where(is_free: false) }  # 有料ページだけ抽出

  # =======================
  # 同一Book内での前後ページ遷移
  # =======================
  def previous
    book.book_sections.where("position < ?", position).order(position: :desc).first
  end

  def next
    book.book_sections.where("position > ?", position).order(position: :asc).first
  end
end
