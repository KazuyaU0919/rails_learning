# app/controllers/admin/quiz_questions_controller.rb
class Admin::QuizQuestionsController < Admin::BaseController
  layout "admin"
  before_action :set_question, only: %i[edit update destroy]

  def index
    @questions = QuizQuestion.includes(:quiz, :quiz_section)
                             .order(created_at: :desc)
                             .page(params[:page])
  end

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

  def edit; end

  def update
    if @question.update(sanitized_params)
      redirect_to admin_quiz_questions_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @question.destroy
    redirect_to admin_quiz_questions_path, notice: "削除しました"
  end

  private

  def set_question
    @question = QuizQuestion.find(params[:id])
  end

  def question_params
    params.require(:quiz_question).permit(
      :quiz_id, :quiz_section_id, :question, :choice1, :choice2, :choice3, :choice4,
      :correct_choice, :position, :explanation
    )
  end

  # Quill の HTML を保存前に“同じ許可リスト”でサニタイズ
  def sanitized_params
    attrs = question_params.dup
    attrs[:question]    = RichTextSanitizer.call(attrs[:question])
    attrs[:explanation] = RichTextSanitizer.call(attrs[:explanation])
    attrs
  end
end
