# app/services/tagging_service.rb
class TaggingService
  MAX_PER_PRE_CODE = 10
  MAX_TAGS_GLOBAL  = (ENV.fetch("MAX_TAGS", "50000").to_i rescue 50000)

  def initialize(pre_code, current_user:)
    @pre_code = pre_code
    @current_user = current_user
  end

  # tag_input: ["Ruby", "array"] or "ruby,array"
  def apply!(tag_input)
    names = Array(tag_input.is_a?(String) ? tag_input.split(",") : tag_input).map(&:to_s).map(&:strip).reject(&:blank?)
    names = names.first(MAX_PER_PRE_CODE)

    tags = names.map { |raw| find_or_create_tag!(raw) }.compact
    @pre_code.tags = tags.uniq
  end

  private

  def find_or_create_tag!(raw)
    norm = Tag.normalize(raw)
    Tag.find_by(name_norm: norm) || create_tag!(raw, norm)
  end

  def create_tag!(raw, norm)
    raise ActiveRecord::RecordInvalid, "上限到達" if Tag.count >= MAX_TAGS_GLOBAL
    Tag.create!(name: raw) # before_validation が name_norm/slug/color を決める
  rescue ActiveRecord::RecordNotUnique
    Tag.find_by!(name_norm: norm) # 競合時は既存を返す
  end
end
