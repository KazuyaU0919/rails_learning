# app/controllers/admin/pre_codes_controller.rb
class Admin::PreCodesController < Admin::BaseController
  layout "admin"
  before_action :set_pre_code, only: %i[show edit update destroy]

  # GET /admin/pre_codes
  def index
    # JOIN させずに別クエリで読み込む（GROUP BY と相性が良い）
    rel  = PreCode.preload(:user, :tags)
    norm = ->(s) { s.to_s.unicode_normalize(:nfkc).downcase }

    if params[:title].present?
      q = "%#{norm.(params[:title])}%"
      rel = rel.where("LOWER(pre_codes.title) LIKE ?", q)
    end

    if params[:description].present?
      q = "%#{norm.(params[:description])}%"
      rel = rel.where("LOWER(pre_codes.description) LIKE ?", q)
    end

    if params[:user].present?
      q = "%#{norm.(params[:user])}%"
      # users 条件のときだけ JOIN。preload は維持されるのでN+1は出ない
      rel = rel.joins(:user).where("LOWER(users.name) LIKE ? OR LOWER(users.email) LIKE ?", q, q)
    end

    # === タグ AND（一般側と同じ “tags（名前）” パラメータ） ===
    if params[:tags].present? && PreCode.reflect_on_association(:tags)
      tag_keys  = parse_tags(params[:tags])
      norm_keys = tag_keys.map { |n| normalize_tag(n) }.uniq

      if norm_keys.any?
        tag_ids = Tag.where(name_norm: norm_keys).pluck(:id)

        rel =
          if tag_ids.any?
            # GROUP/HAVING を使う枝では SELECT を pre_codes.* に固定して安全にする
            rel.joins(:tags)
               .where(tags: { id: tag_ids })
               .group("pre_codes.id")
               .having("COUNT(DISTINCT tags.id) = ?", tag_ids.size)
               .select("pre_codes.*")
          else
            rel.none
          end
      end
    end

    rel =
      case params[:sort]
      when "likes" then rel.order(like_count: :desc, created_at: :desc)
      when "used"  then rel.order(use_count:  :desc, created_at: :desc)
      when "title" then rel.order(Arel.sql("LOWER(pre_codes.title) ASC"))
      else               rel.order(created_at: :desc)
      end

    @pre_codes = rel.page(params[:page]).per(50)
  end

  def show; end
  def edit; end

  def update
    @pre_code.quiz_mode = params.dig(:pre_code, :quiz_mode)

    attrs = pre_code_params_with_sanitized_text

    if @pre_code.update(attrs)
      replace_tags(@pre_code, params[:tag_names])
      redirect_to [ :admin, @pre_code ], notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pre_code.destroy!
    redirect_to admin_pre_codes_path(request.query_parameters), notice: "削除しました"
  end

  private

  def set_pre_code
    @pre_code = PreCode.find(params[:id])
  end

  # ===== Strong Params（一般側と合わせる） =====
  def pre_code_params
    params.require(:pre_code).permit(
      :title, :description, :body,
      :hint, :answer, :answer_code,
      :quiz_mode
    )
  end

  # テキスト系は保存前にサニタイズ（一般側と同等）
  def pre_code_params_with_sanitized_text
    attrs = pre_code_params

    sanitizer =
      if respond_to?(:sanitize_content, true)
        method(:sanitize_content)
      else
        ->(html) {
          ActionController::Base.helpers.sanitize(
            html,
            tags: %w[b i em strong code pre br p ul ol li a],
            attributes: %w[href]
          )
        }
      end

    attrs[:hint]   = sanitizer.call(attrs[:hint])   if attrs.key?(:hint)
    attrs[:answer] = sanitizer.call(attrs[:answer]) if attrs.key?(:answer)
    attrs
  end

  # ===== タグ関連（一般側と同等の「文字列」入力を受ける） =====
  def replace_tags(pre_code, raw_names)
    return if raw_names.nil?

    names = raw_names.to_s.tr("　", " ")
                       .split(/[,\s]+/)
                       .map(&:strip)
                       .reject(&:blank?)
                       .uniq

    new_tags = names.map { |n| Tag.find_or_create_by!(name: n) }
    pre_code.tags = new_tags
  end

  # === 一覧検索用の補助（一般側と同等） ===
  def parse_tags(val)
    Array(val).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
  end

  def normalize_tag(name)
    if Tag.respond_to?(:normalize)
      Tag.normalize(name)
    else
      name.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " ")
    end
  end
end
