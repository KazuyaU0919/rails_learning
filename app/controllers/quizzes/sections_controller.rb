# ============================================================
# Quizzes::SectionsController
# ------------------------------------------------------------
# クイズ教材の「セクション」単位の画面を管理。
# - index   : 最初のセクションへリダイレクト
# - show    : 最初の問題へ誘導（または empty 表示）
# - result  : セクション別の解答結果を表示
#
# セクションごとのスコアはセッションに保存され、
# FREE でないセクションにはログイン必須。
# ============================================================

class Quizzes::SectionsController < ApplicationController
  before_action :set_quiz
  before_action :set_section
  before_action :ensure_access!

  # =======================
  # 一覧 → 最初のセクションへリダイレクト
  # =======================
  def index
    redirect_to quiz_section_path(@quiz, @quiz.quiz_sections.first)
  end

  # =======================
  # セクション詳細（＝最初の問題へ誘導）
  # =======================
  def show
    first_question = @section.quiz_questions.first
    if first_question
      redirect_to quiz_section_question_path(@quiz, @section, first_question)
    else
      render :empty # 問題未登録時専用のテンプレート
    end
  end

  # =======================
  # 結果画面（正答数などを集計）
  # =======================
  def result
    scores   = session_scores_for(@section.id)
    @total   = @section.quiz_questions.count
    @correct = scores.values.count(true)
  end

  private

  # =======================
  # セットアップ
  # =======================
  def set_quiz    = @quiz    = Quiz.find(params[:quiz_id])
  def set_section = @section = @quiz.quiz_sections.find(params[:id])

  # =======================
  # アクセス制御
  #   - FREEセクションは誰でもOK
  #   - それ以外はログイン必須
  # =======================
  def ensure_access!
    return if @section.is_free
    return if respond_to?(:logged_in?, true) ? send(:logged_in?) : current_user.present?

    store_location(quiz_section_path(@quiz, @section)) if respond_to?(:store_location, true)
    redirect_to new_session_path, alert: "このクイズを解くにはログインが必要です"
  end

  # =======================
  # セッション上のスコア記録領域を取得
  # （section_idごとにハッシュを保持）
  # =======================
  def session_scores_for(section_id)
    session[:quiz_scores] ||= {}
    session[:quiz_scores][section_id.to_s] ||= {}
  end
end
