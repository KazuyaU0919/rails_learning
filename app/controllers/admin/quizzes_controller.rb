# app/controllers/admin/quizzes_controller.rb
class Admin::QuizzesController < Admin::BaseController
  layout "admin"

  def index
    @quizzes = Quiz.order(position: :asc, updated_at: :desc).page(params[:page])
  end

  def new    = @quiz = Quiz.new
  def edit   = @quiz = Quiz.find(params[:id])

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

  def destroy
    Quiz.find(params[:id]).destroy
    redirect_to admin_quizzes_path, notice: "削除しました"
  end

  private

  def quiz_params
    params.require(:quiz).permit(:title, :description, :position)
  end
end
