# app/controllers/quizzes_controller.rb
class QuizzesController < ApplicationController
  def index
    @quizzes = Quiz.order(position: :asc, updated_at: :desc).page(params[:page])
  end

  def show
    @quiz = Quiz.includes(:quiz_sections).find(params[:id])
    @sections = @quiz.quiz_sections # position順スコープ済
  end
end
