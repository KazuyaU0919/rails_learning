# ============================================================
# 管理: クイズ本体 (Quiz)
# ------------------------------------------------------------
# ・タイトル、説明、並び順を管理
# ・基本 CRUD
# ============================================================
class Admin::QuizzesController < Admin::BaseController
  layout "admin"

  # =======================
  # 一覧
  # =======================
  def index
    @quizzes = Quiz.order(position: :asc, updated_at: :desc)
                   .page(params[:page])
  end

  # =======================
  # 新規作成・編集
  # =======================
  def new  = @quiz = Quiz.new
  def edit = @quiz = Quiz.find(params[:id])

  def create
    @quiz = Quiz.new(quiz_params)
    if @quiz.save
      redirect_to admin_quizzes_path, notice: "クイズを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @quiz = Quiz.find(params[:id])
    if @quiz.update(quiz_params)
      redirect_to admin_quizzes_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # =======================
  # 削除
  # =======================
  def destroy
    Quiz.find(params[:id]).destroy
    redirect_to admin_quizzes_path, notice: "削除しました"
  end

  private

  # =======================
  # Strong Parameters
  # =======================
  def quiz_params
    params.require(:quiz).permit(:title, :description, :position)
  end
end
