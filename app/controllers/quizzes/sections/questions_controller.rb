# app/controllers/quizzes/sections/questions_controller.rb
class Quizzes::Sections::QuestionsController < ApplicationController
  include EditPermission
  before_action :set_quiz_and_section
  before_action :ensure_access!
  before_action :set_question, only: %i[show edit update answer answer_page]

  def show
    @next_q = @section.quiz_questions.where("position > ?", @question.position).order(:position).first
    @prev_q = @section.quiz_questions.where("position < ?", @question.position).order(position: :desc).first
    @answer_state = scores[@question.id.to_s]
  end

  def edit
    nil unless require_edit_permission!(@question)
  end

  def update
    return unless require_edit_permission!(@question)

    attrs = question_params.slice(*@question.editable_attributes).merge(lock_version: question_params[:lock_version])
    @question.assign_attributes(attrs)

    begin
      if @question.save
        redirect_to quiz_section_question_path(@quiz, @section, @question),
                    notice: "問題を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    rescue ActiveRecord::StaleObjectError
      flash.now[:alert] = "他の編集と競合しました。最新の内容を確認して再度保存してください。"
      render :edit, status: :conflict
    end
  end

  # POST /.../questions/:id/answer
  def answer
    @question = @section.quiz_questions.find(params[:id])
    selected  = params[:choice].to_i
    correct   = (selected == @question.correct_choice)

    scores[@question.id.to_s] = correct

    # ★ PRG: GET にリダイレクトして解説を表示
    redirect_to answer_page_quiz_section_question_path(@quiz, @section, @question,
                   choice: selected),
                status: :see_other
  end

  # GET /.../questions/:id/answer_page
  def answer_page
    @question = @section.quiz_questions.find(params[:id])
    @next_q   = @section.quiz_questions.where("position > ?", @question.position).order(:position).first
    render :answer
  end

  private

  def set_quiz_and_section
    @quiz    = Quiz.find(params[:quiz_id])
    @section = @quiz.quiz_sections.find(params[:section_id])
  end

  def set_question
    @question = @section.quiz_questions.find(params[:id])
  end

  def question_params
    params.require(:quiz_question).permit(
      :question, :choice1, :choice2, :choice3, :choice4, :correct_choice, :explanation, :lock_version
    )
  end

  def ensure_access!
    return if @section.is_free
    return if respond_to?(:logged_in?, true) ? send(:logged_in?) : current_user.present?
    store_location(quiz_section_path(@quiz, @section)) if respond_to?(:store_location, true)
    redirect_to new_session_path, alert: "このクイズを解くにはログインが必要です"
  end

  def scores
    session[:quiz_scores] ||= {}
    session[:quiz_scores][@section.id.to_s] ||= {}
  end
end
