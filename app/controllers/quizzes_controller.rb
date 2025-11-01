# ============================================================
# QuizzesController
# ------------------------------------------------------------
# クイズ教材（Quiz）の一覧・詳細表示を提供。
# ------------------------------------------------------------
# 主な責務：
#   - クイズ一覧（position + 更新順）
#   - クイズ詳細（QuizSection含む）
# ============================================================

class QuizzesController < ApplicationController
  def index
    @quizzes = Quiz.order(position: :asc, updated_at: :desc).page(params[:page])
  end

  def show
    @quiz = Quiz.includes(:quiz_sections).find(params[:id])
    @sections = @quiz.quiz_sections # position順スコープ済
  end
end
