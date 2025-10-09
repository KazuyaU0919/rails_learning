# app/models/book_section.rb
class BookSection < ApplicationRecord
  has_paper_trail
  belongs_to :book, counter_cache: true, touch: true
  belongs_to :quiz_section, optional: true
  has_many_attached :images

  # 見出し50 / 本文3万文字 / 表示順 0..9999（0許容：目次など）/ 画像は25枚まで
  validates :heading,  presence: true, length: { maximum: 50 }
  validates :content,  presence: true, length: { maximum: 30_000 }
  validates :position,
           presence: true,
           numericality: {
             only_integer: true,
             greater_than_or_equal_to: 0,
             less_than_or_equal_to: 9_999
           },
           uniqueness: { scope: :book_id }

  validate :image_count_within_limit

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

  # =======================
  # 編集権限チェック
  # =======================
  def editable_attributes
    %i[content]
  end

  private

  def image_count_within_limit
    return unless images.attached?
    if images.attachments.size > 25
      errors.add(:images, I18n.t!("errors.messages.too_many_images", max: 25))
    end
  end
end
