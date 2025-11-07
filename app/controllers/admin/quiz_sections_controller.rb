# ============================================================
# 管理: クイズセクション (QuizSection)
# ------------------------------------------------------------
# ・クイズごとの章（セクション）管理
# ・CRUD実装のみ（単純構造）
# ・一覧は Ransack で quizzes.title / quiz_sections.heading を検索
# ============================================================
class Admin::QuizSectionsController < Admin::BaseController
  layout "admin"

  # =======================
  # 一覧
  # =======================
  def index
    base = QuizSection.includes(:quiz)
    @q = base.ransack(params[:q])
    @sections = @q.result.includes(:quiz).order(updated_at: :desc).page(params[:page])
  end

  # =======================
  # 新規作成・編集
  # =======================
  def new    = @section = QuizSection.new
  def edit   = @section = QuizSection.find(params[:id])

  def create
    @section = QuizSection.new(section_params)
    if @section.save
      redirect_to admin_quiz_sections_path, notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @section = QuizSection.find(params[:id])
    if @section.update(section_params)
      redirect_to admin_quiz_sections_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # =======================
  # 削除
  # =======================
  def destroy
    QuizSection.find(params[:id]).destroy
    redirect_to admin_quiz_sections_path, notice: "削除しました"
  end

  # =======================
  # 依存ドロップダウン用: Quiz に紐づくセクション一覧を返す
  # GET /admin/quiz_sections/options?quiz_id=1
  # =======================
  def options
    sections = QuizSection.where(quiz_id: params[:quiz_id]).order(:position)
    render json: sections.select(:id, :heading).map { |s| { id: s.id, text: s.heading } }
  end

  private

  # =======================
  # Strong Parameters
  # =======================
  def section_params
    params.require(:quiz_section)
          .permit(:quiz_id, :heading, :is_free, :position, :book_section_id)
  end
end
