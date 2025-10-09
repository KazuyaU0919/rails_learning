# app/models/pre_code.rb
class PreCode < ApplicationRecord
  # --- 仮想属性（保存しない） ---
  attr_accessor :quiz_mode

  belongs_to :user
  has_many :likes,      dependent: :destroy
  has_many :used_codes, dependent: :destroy
  has_many :pre_code_taggings, dependent: :destroy
  has_many :tags, through: :pre_code_taggings
  has_many :bookmarks, dependent: :destroy

  validates :title,
            presence: true,
            length: { maximum: 50 },
            format: { without: /\A\s*\z/, message: I18n.t!("errors.messages.blank_only") }

  validates :description, length: { maximum: 2_000 }
  validates :body,        presence: true, length: { maximum: 5_000 }
  validates :hint,        length: { maximum: 1_000 }, allow_blank: true
  validates :answer,      length: { maximum: 2_000 }, allow_blank: true
  validates :answer_code, length: { maximum: 2_000 }, allow_blank: true

  # Quiz モードのときだけ answer を必須にする
  validates :answer, presence: true, if: :quiz_mode?

  # === 一覧・並び替え向けスコープ ===
  scope :except_user, ->(uid) { uid.present? ? where.not(user_id: uid) : all }
  scope :popular,     ->       { order(like_count: :desc, id: :desc) }
  scope :most_used,   ->       { order(use_count: :desc,  id: :desc) }
  scope :tagged_with_all, ->(tag_ids) {
    next all if tag_ids.blank?
    joins(:tags)
      .where(tags: { id: tag_ids })
      .group("pre_codes.id")
      .having("COUNT(DISTINCT tags.id) = ?", Array(tag_ids).size)
  }

  # === Ransack 4 (Rails 7+) 許可リスト ===
  def self.ransackable_attributes(_auth = nil)
    %w[title description like_count use_count created_at user_id]
  end

  def self.ransackable_associations(_auth = nil)
    %w[user]
  end

  # boolean キャストして判定（"true"/"1"/true を true に）
  def quiz_mode?
    ActiveModel::Type::Boolean.new.cast(@quiz_mode)
  end
end
