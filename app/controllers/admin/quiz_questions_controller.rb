# app/controllers/admin/quiz_questions_controller.rb
class Admin::QuizQuestionsController < Admin::BaseController
  layout "admin"

  def index
    @questions = QuizQuestion.includes(:quiz, :quiz_section).order(updated_at: :desc).page(params[:page])
  end

  def new    = @question = QuizQuestion.new
  def edit   = @question = QuizQuestion.find(params[:id])

  def create
    @question = QuizQuestion.new(question_params)
    if @question.save
      redirect_to admin_quiz_questions_path, notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @question = QuizQuestion.find(params[:id])
    if @question.update(question_params)
      redirect_to admin_quiz_questions_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    QuizQuestion.find(params[:id]).destroy
    redirect_to admin_quiz_questions_path, notice: "削除しました"
  end

  private

  def question_params
    params.require(:quiz_question).permit(
      :quiz_id, :quiz_section_id, :question,
      :choice1, :choice2, :choice3, :choice4,
      :correct_choice, :explanation, :position
    )
  end
end
