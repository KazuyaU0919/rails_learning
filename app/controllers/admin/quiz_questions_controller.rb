# ============================================================
# 管理: クイズ問題 (QuizQuestion)
# ------------------------------------------------------------
# ・CRUD操作（一覧・作成・更新・削除）
# ・保存前に Quill のHTMLを RichTextSanitizer でサニタイズ
# ・クイズやセクションとのリレーションを includes で最適化
# ・一覧は Ransack で quizzes.title / quiz_sections.heading を検索
# ============================================================
class Admin::QuizQuestionsController < Admin::BaseController
  layout "admin"
  before_action :set_question, only: %i[edit update destroy]

  # =======================
  # 一覧
  # =======================
  def index
    base = QuizQuestion.includes(:quiz, :quiz_section)
    @q = base.ransack(params[:q])
    @questions = @q.result
                   .includes(:quiz, :quiz_section)
                   .order(created_at: :desc)
                   .page(params[:page])
  end

  # =======================
  # 新規作成
  # =======================
  def new
    @question = QuizQuestion.new
  end

  def create
    @question = QuizQuestion.new(sanitized_params)
    if @question.save
      redirect_to admin_quiz_questions_path, notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # =======================
  # 編集・更新
  # =======================
  def edit; end

  def update
    if @question.update(sanitized_params)
      redirect_to admin_quiz_questions_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # =======================
  # 削除
  # =======================
  def destroy
    @question.destroy
    redirect_to admin_quiz_questions_path, notice: "削除しました"
  end

  private

  # =======================
  # 共通セットアップ
  # =======================
  def set_question
    @question = QuizQuestion.find(params[:id])
  end

  # =======================
  # Strong Parameters
  # =======================
  def question_params
    params.require(:quiz_question).permit(
      :quiz_id, :quiz_section_id,
      :question, :choice1, :choice2, :choice3, :choice4,
      :correct_choice, :position, :explanation
    )
  end

  # =======================
  # サニタイズ処理
  # -----------------------
  # QuillエディタのHTMLを安全なタグのみ残す。
  # RichTextSanitizer.call で全フィールド統一処理。
  # =======================
  def sanitized_params
    attrs = question_params.dup
    attrs[:question]    = RichTextSanitizer.call(attrs[:question])
    attrs[:explanation] = RichTextSanitizer.call(attrs[:explanation])
    attrs
  end
end
