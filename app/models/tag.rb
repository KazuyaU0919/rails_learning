# ============================================================
# Tag
# ------------------------------------------------------------
# PreCode に付与するタグ。利用回数（taggings_count）や未使用期間
# (zero_since) を持ち、提案/クリーンアップのための補助メソッドを提供。
# ============================================================

class Tag < ApplicationRecord
  # =======================
  # 関連
  # =======================
  has_many :pre_code_taggings, dependent: :destroy
  has_many :pre_codes, through: :pre_code_taggings

  # =======================
  # コールバック
  # =======================
  before_validation :set_normalized_fields

  # =======================
  # バリデーション
  # =======================
  # ★ 1文字以上「30文字未満」 => maximum: 29
  validates :name,      presence: true, length: { minimum: 1, maximum: 29 }
  validates :name_norm, presence: true, uniqueness: true
  validates :color,     format: { with: /\A#[0-9A-Fa-f]{6}\z/ }, allow_blank: true

  # =======================
  # スコープ
  # =======================
  scope :used,   -> { where("taggings_count > 0") }
  scope :prefix, ->(q) { where("name_norm LIKE ?", "#{normalize(q)}%") if q.present? }
  scope :order_for_suggest, -> { order(taggings_count: :desc, name_norm: :asc) }

  # =======================
  # class ユーティリティ
  # =======================
  def self.normalize(s) = ActiveSupport::Inflector.transliterate(s.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " "))

  def self.slugify(s)
    base = normalize(s).gsub(/[^a-z0-9\- ]/, "").tr(" ", "-").gsub(/\-+/, "-")
    base.presence || "tag"
  end

  # 未使用が一定期間継続したタグを削除
  def self.cleanup_unused!(older_than: 10.days)
    where("taggings_count = 0")
      .where("zero_since IS NOT NULL")
      .where("zero_since <= ?", Time.current - older_than)
      .find_each(&:destroy!)
  end

  # =======================
  # インスタンスユーティリティ
  # =======================
  # taggings_count に応じて zero_since を更新
  def refresh_zero_since!
    if taggings_count.to_i.zero?
      update_columns(zero_since: (zero_since || Time.current), updated_at: Time.current)
    else
      update_columns(zero_since: nil, updated_at: Time.current) if zero_since.present?
    end
  end

  private

  # name/name_norm/slug/color を正規化・自動生成
  def set_normalized_fields
    self.name      = name.to_s.strip if name
    self.name_norm = Tag.normalize(name) if name

    self.slug    ||= begin
      base = Tag.slugify(name)
      candidate = base
      i = 2
      while Tag.exists?(slug: candidate) && Tag.find_by(slug: candidate) != self
        candidate = "#{base}-#{i}"
        i += 1
      end
      candidate
    end

    self.color   ||= auto_color(name_norm)
  end

  # name_norm に基づいて安定した色を生成（HSL の Hue をCRCで決定）
  def auto_color(key)
    h = Zlib.crc32(key.to_s) % 360
    s = 55; l = 65
    Color::HSL.new(h, s, l).to_rgb.html
  rescue
    "#6B7280"
  end
end
