# ============================================================
# Quizzes::Sections::QuestionsController
# ------------------------------------------------------------
# クイズ各セクション内の「問題」管理。
# - show        : 問題表示
# - edit/update : 管理者または編集権限者による編集
# - answer      : 回答送信処理（正誤判定＋セッション保存）
# - answer_page : 回答結果ページ表示
#
# ログイン必須（FREEでない場合）。
# ============================================================

class Quizzes::Sections::QuestionsController < ApplicationController
  include EditPermission

  before_action :set_quiz_and_section
  before_action :ensure_access!
  before_action :set_question, only: %i[show edit update answer answer_page]

  # =======================
  # 問題表示
  # =======================
  def show
    @next_q = @section.quiz_questions.where("position > ?", @question.position).order(:position).first
    @prev_q = @section.quiz_questions.where("position < ?", @question.position).order(position: :desc).first
    @answer_state = scores[@question.id.to_s] # 正答済み状態をセッションから取得
  end

  # =======================
  # 編集フォーム
  # =======================
  def edit
    nil unless require_edit_permission!(@question)
  end

  # =======================
  # 更新処理（楽観ロック対応）
  # =======================
  def update
    return unless require_edit_permission!(@question)

    attrs = question_params.slice(*@question.editable_attributes)
    attrs[:lock_version] = question_params[:lock_version]

    # リッチテキストの sanitize
    attrs[:question]    = RichTextSanitizer.call(attrs[:question])    if attrs.key?(:question)
    attrs[:explanation] = RichTextSanitizer.call(attrs[:explanation]) if attrs.key?(:explanation)

    @question.assign_attributes(attrs)

    begin
      if @question.save
        redirect_to quiz_section_question_path(@quiz, @section, @question), notice: "問題を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    rescue ActiveRecord::StaleObjectError
      flash.now[:alert] = "他の編集と競合しました。最新の内容を確認して再度保存してください。"
      render :edit, status: :conflict
    end
  end

  # =======================
  # 回答送信（POST）
  # =======================
  def answer
    @question = @section.quiz_questions.find(params[:id])
    selected  = params[:choice].to_i
    correct   = (selected == @question.correct_choice)

    scores[@question.id.to_s] = correct
    redirect_to answer_page_quiz_section_question_path(@quiz, @section, @question, choice: selected),
                status: :see_other
  end

  # =======================
  # 回答結果ページ
  # =======================
  def answer_page
    @question = @section.quiz_questions.find(params[:id])
    @next_q   = @section.quiz_questions.where("position > ?", @question.position).order(:position).first
    render :answer
  end

  private

  # =======================
  # 共通セットアップ
  # =======================
  def set_quiz_and_section
    @quiz    = Quiz.find(params[:quiz_id])
    @section = @quiz.quiz_sections.find(params[:section_id])
  end

  def set_question
    @question = @section.quiz_questions.find(params[:id])
  end

  # =======================
  # Strong Parameters
  # =======================
  def question_params
    params.require(:quiz_question).permit(
      :question, :choice1, :choice2, :choice3, :choice4,
      :correct_choice, :explanation, :lock_version
    )
  end

  # =======================
  # アクセス制御（FREEでない場合はログイン必須）
  # =======================
  def ensure_access!
    return if @section.is_free
    return if respond_to?(:logged_in?, true) ? send(:logged_in?) : current_user.present?

    store_location(quiz_section_path(@quiz, @section)) if respond_to?(:store_location, true)
    redirect_to new_session_path, alert: "このクイズを解くにはログインが必要です"
  end

  # =======================
  # セッション上のスコア記録領域
  # =======================
  def scores
    session[:quiz_scores] ||= {}
    session[:quiz_scores][@section.id.to_s] ||= {}
  end
end
