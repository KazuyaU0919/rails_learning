# ============================================================
# BookSection
# ------------------------------------------------------------
# 書籍(Book)の各セクション（章/ページ）を表すモデル。
# 本文・見出し・表示順・無料/有料の区分・画像添付を持つ。
# 変更は PaperTrail で履歴管理する。
# ============================================================

class BookSection < ApplicationRecord
  # =======================
  # 関連
  # =======================
  belongs_to :book, counter_cache: true, touch: true
  belongs_to :quiz_section, optional: true
  has_many_attached :images

  # PaperTrail（変更履歴）
  has_paper_trail

  # =======================
  # バリデーション
  # =======================
  validates :heading, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { maximum: 30_000 }
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
  scope :free, -> { where(is_free: true) }
  scope :paid, -> { where(is_free: false) }

  # =======================
  # ページ遷移（同一 Book 内）
  # =======================
  def previous
    book.book_sections.where("position < ?", position).order(position: :desc).first
  end

  def next
    book.book_sections.where("position > ?", position).order(position: :asc).first
  end

  # =======================
  # 編集権限（編集可能カラム）
  # =======================
  def editable_attributes
    %i[content]
  end

  # =======================
  # Ransack 許可
  # -----------------------
  # 管理画面の検索で使うカラム・関連をホワイトリスト化
  # =======================
  def self.ransackable_attributes(_auth = nil)
    %w[heading position created_at updated_at]
  end

  def self.ransackable_associations(_auth = nil)
    %w[book]
  end

  private

  # =======================
  # 独自バリデーション
  # =======================
  # 添付画像は最大25枚まで
  def image_count_within_limit
    return unless images.attached?
    if images.attachments.size > 25
      errors.add(:images, I18n.t!("errors.messages.too_many_images", max: 25))
    end
  end
end
