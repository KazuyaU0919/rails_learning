# app/controllers/admin/quiz_sections_controller.rb
class Admin::QuizSectionsController < Admin::BaseController
  layout "admin"

  def index
    @sections = QuizSection.includes(:quiz).order(updated_at: :desc).page(params[:page])
  end

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

  def destroy
    QuizSection.find(params[:id]).destroy
    redirect_to admin_quiz_sections_path, notice: "削除しました"
  end

  private

  def section_params
    params.require(:quiz_section).permit(:quiz_id, :heading, :is_free, :position)
  end
end
