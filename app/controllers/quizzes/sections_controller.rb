# app/controllers/quizzes/sections_controller.rb
class Quizzes::SectionsController < ApplicationController
  before_action :set_quiz
  before_action :set_section
  before_action :ensure_access!

  def index
    redirect_to quiz_section_path(@quiz, @quiz.quiz_sections.first) and return
  end

  def show
    # 最初の問題へ誘導
    q = @section.quiz_questions.first
    if q
      redirect_to quiz_section_question_path(@quiz, @section, q)
    else
      render :empty # 問題未登録用（任意）
    end
  end

  def result
    scores = session_scores_for(@section.id)
    @total = @section.quiz_questions.count
    @correct = scores.values.count(true)
  end

  private

  def set_quiz    = @quiz    = Quiz.find(params[:quiz_id])
  def set_section = @section = @quiz.quiz_sections.find(params[:id])

  # FREE 以外はログイン必須
  def ensure_access!
    return if @section.is_free
    return if respond_to?(:logged_in?, true) ? send(:logged_in?) : current_user.present?

    # 既存のストアロケーションヘルパがあれば利用
    store_location(quiz_section_path(@quiz, @section)) if respond_to?(:store_location, true)
    redirect_to new_session_path, alert: "このクイズを解くにはログインが必要です"
  end

  # セクション毎のスコア保存領域（セッション）
  def session_scores_for(section_id)
    session[:quiz_scores] ||= {}
    session[:quiz_scores][section_id.to_s] ||= {}
  end
end
