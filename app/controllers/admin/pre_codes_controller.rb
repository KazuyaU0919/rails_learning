# app/controllers/admin/pre_codes_controller.rb
class Admin::PreCodesController < Admin::BaseController
  layout "admin"
  before_action :set_pre_code, only: %i[show edit update destroy]

  # GET /admin/pre_codes
  def index
    rel = PreCode.includes(:user) # （タグがあれば :tags も）
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

    # タグ AND（Tag/Tagging がある場合）
    if PreCode.reflect_on_association(:tags) && (tag_ids = Array(params[:tag_ids]).reject(&:blank?)).present?
      rel = rel.joins(:tags).where(tags: { id: tag_ids })
               .group("pre_codes.id").having("COUNT(DISTINCT tags.id) = ?", tag_ids.size)
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
    if @pre_code.update(pre_code_params)
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

  # 一般フォームと同じパラメータに合わせる（存在しない項目は削除OK）
  def pre_code_params
    params.require(:pre_code).permit(:title, :description, :body, :hint, :answer, :problem_mode, tag_ids: [])
  end
end
