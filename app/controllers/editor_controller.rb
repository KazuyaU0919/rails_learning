# app/controllers/editor_controller.rb
class EditorController < ApplicationController
  # JSON 以外は弾く
  before_action :ensure_json!, only: %i[create pre_code_body]
  protect_from_forgery with: :null_session, only: :create

  # 制御文字（NULL 〜 US、DEL など）を禁止
  FORBIDDEN_CTRL_RE = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/.freeze
  MAX_CODE_BYTES = 200_000 # 既存仕様を維持

  # GET /editor
  def index
    if logged_in?
      # 自分のデータ
      @own_pre_codes = current_user.pre_codes.order(created_at: :desc).limit(100)

      # ブックマークしたデータ（自分の分は除外して重複排除）
      bookmarked_ids = Bookmark.where(user_id: current_user.id).select(:pre_code_id)
      @bookmarked_pre_codes =
        PreCode.includes(:user)
               .where(id: bookmarked_ids)
               .where.not(user_id: current_user.id)
               .order(created_at: :desc)
               .limit(100)
    else
      @own_pre_codes = PreCode.none
      @bookmarked_pre_codes = PreCode.none
    end
  end

  # POST /editor
  def create
    code    = params[:code].to_s
    lang_id = params[:language_id].presence || Judge0::Client::RUBY_LANG_ID

    if code.strip.empty?
      render json: { stdout: "", stderr: I18n.t!("editor.errors.blank") }, status: :unprocessable_entity and return
    end
    if code.bytesize > MAX_CODE_BYTES
      render json: { stdout: "", stderr: I18n.t!("editor.errors.too_large") }, status: :unprocessable_entity and return
    end
    if code.match?(FORBIDDEN_CTRL_RE)
      render json: { stdout: "", stderr: I18n.t!("editor.errors.forbidden_chars") }, status: :unprocessable_entity and return
    end

    result = Judge0::Client.new.run_ruby(code, language_id: lang_id)
    render json: { stdout: result["stdout"] || "", stderr: result["stderr"] || "" }
  rescue Judge0::Error => e
    render json: { stdout: "", stderr: e.message }, status: :bad_gateway
  end

  # GET /pre_codes/:id/body  （エディタ用：詳細もまとめて返す）
  def pre_code_body
    pc = PreCode.find(params[:id])

    # 「問題モード」判定：answer/answer_code どちらかがあれば true
    is_quiz = pc.answer.present? || pc.answer_code.present?

    sanitize_html = lambda do |html|
      ActionController::Base.helpers.sanitize(
        html.to_s,
        tags:  %w[b i em strong code pre br p ul ol li a],
        attributes: %w[href]
      )
    end

    render json: {
      id: pc.id,
      title: pc.title,
      description_html: sanitize_html.call(pc.description),
      body: pc.body,
      is_quiz: is_quiz,
      hint_html: sanitize_html.call(pc.hint),
      answer_html: sanitize_html.call(pc.answer),
      answer_code: pc.answer_code.to_s
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not found" }, status: :not_found
  end

  private

  def ensure_json!
    return if request.format.json?
    head :not_acceptable
  end
end
