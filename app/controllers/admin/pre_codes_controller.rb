# app/controllers/admin/pre_codes_controller.rb
class Admin::PreCodesController < Admin::BaseController
  layout "admin"
  before_action :set_pre_code, only: %i[show edit update destroy]

  # GET /admin/pre_codes
  def index
    rel  = PreCode.includes(:user) # タグも読むなら :tags を preload へ
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
      rel = rel.joins(:user).where("LOWER(users.name) LIKE ? OR LOWER(users.email) LIKE ?", q, q)
    end

    # タグ AND（タグ機能がある場合）
    if PreCode.reflect_on_association(:tags) && (tag_ids = Array(params[:tag_ids]).reject(&:blank?)).present?
      rel = rel.joins(:tags).where(tags: { id: tag_ids })
               .group("pre_codes.id")
               .having("COUNT(DISTINCT tags.id) = ?", tag_ids.size)
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
    # 一般側と同様：quiz_mode の有無で answer を必須にするため、更新前にセット
    @pre_code.quiz_mode = params.dig(:pre_code, :quiz_mode)

    attrs = pre_code_params_with_sanitized_text

    if @pre_code.update(attrs)
      # タグ（文字列: "ruby, array"）を置換
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
  # "ruby, array" / ["ruby", "array"] を配列化して正規化なしで登録（必要なら Tag.normalize を利用）
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
end
