class PreCode < ApplicationRecord
  belongs_to :user
  has_many :likes,      dependent: :destroy
  has_many :used_codes, dependent: :destroy

  validates :title,
            presence: true,
            length: { maximum: 50 },
            format: { without: /\A\s*\z/, message: "を空白だけにはできません" }

  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :body, presence: true

  # === 一覧向けスコープ ===
  scope :except_user, ->(user_id) { user_id.present? ? where.not(user_id: user_id) : all }
  scope :popular,     -> { order(like_count: :desc, id: :desc) }
  scope :most_used,   -> { order(use_count: :desc,   id: :desc) }
  scope :keyword,     ->(kw) {
    next all if kw.blank?
    where("title ILIKE :q OR description ILIKE :q", q: "%#{kw}%")
  }
end
