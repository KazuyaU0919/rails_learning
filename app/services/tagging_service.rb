# ============================================================
# Service: TaggingService
# ------------------------------------------------------------
# PreCode に対するタグ付けを一括で扱うサービス。
# - 1件あたりの最大タグ数制限
# - 全体のタグ数上限（ENV["MAX_TAGS"]）に達した場合の保護
# - 競合時（同名を同時作成）でも冪等に動作
# 入力形式:
# - 配列 ["Ruby","array"] もしくは 文字列 "ruby,array"
# ============================================================
class TaggingService
  MAX_PER_PRE_CODE = 10
  MAX_TAGS_GLOBAL  = (ENV.fetch("MAX_TAGS", "50000").to_i rescue 50000)

  def initialize(pre_code, current_user:)
    @pre_code = pre_code
    @current_user = current_user
  end

  # =======================
  # タグ適用（置換）
  # -----------------------
  # 引数:
  #   tag_input: ["Ruby", "array"] or "ruby,array"
  # 動作:
  #   1) 正規化前の生文字列を上限数まで採用
  #   2) 既存Tag検索 → なければ作成 → 重複排除
  #   3) pre_code.tags を置き換え
  # =======================
  def apply!(tag_input)
    names = Array(tag_input.is_a?(String) ? tag_input.split(",") : tag_input)
              .map(&:to_s).map(&:strip).reject(&:blank?)
    names = names.first(MAX_PER_PRE_CODE)

    tags = names.map { |raw| find_or_create_tag!(raw) }.compact
    @pre_code.tags = tags.uniq
  end

  private
  # =======================
  # 既存タグの検索 or 作成
  # =======================
  def find_or_create_tag!(raw)
    norm = Tag.normalize(raw)
    Tag.find_by(name_norm: norm) || create_tag!(raw, norm)
  end

  # =======================
  # タグ作成（衝突に強い）
  # -----------------------
  # - 全体上限（MAX_TAGS_GLOBAL）を超える場合は例外
  # - UNIQUE制約衝突時は既存を返す
  # =======================
  def create_tag!(raw, norm)
    raise ActiveRecord::RecordInvalid, "上限到達" if Tag.count >= MAX_TAGS_GLOBAL
    Tag.create!(name: raw) # before_validation で name_norm/slug/color を決定
  rescue ActiveRecord::RecordNotUnique
    Tag.find_by!(name_norm: norm)
  end
end
