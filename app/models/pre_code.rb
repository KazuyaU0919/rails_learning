class PreCode < ApplicationRecord
  belongs_to :user

  validates :title,
            presence: true,
            length: { maximum: 50 },
            format: { without: /\A\s*\z/, message: "を空白だけにはできません" }

  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :body, presence: true

  # 将来 Like / UsedCode を入れるときは解放
  # has_many :likes,      dependent: :destroy
  # has_many :used_codes, dependent: :destroy
end
