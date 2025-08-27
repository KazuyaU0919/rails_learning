# app/controllers/editor_controller.rb
class EditorController < ApplicationController
  # JSON以外は弾く（明示的に406を返す）
  before_action :ensure_json!, only: %i[create pre_code_body]
  protect_from_forgery with: :null_session, only: :create

  # GET /editor
  def index
    @my_pre_codes = logged_in? ? current_user.pre_codes.order(created_at: :desc).limit(30) : PreCode.none
    @popular_public = PreCode.order(like_count: :desc).limit(30)
  end

  # POST /editor
  def create
    code    = params[:code].to_s
    lang_id = params[:language_id].presence || Judge0::Client::RUBY_LANG_ID

    # 空や過大リクエストの防御
    if code.strip.empty?
      render json: { stdout: "", stderr: "code が空です" }, status: :unprocessable_entity and return
    end
    if code.bytesize > 200_000
      render json: { stdout: "", stderr: "code が大きすぎます" }, status: :unprocessable_entity and return
    end

    # Judge0 実行
    result = Judge0::Client.new.run_ruby(code, language_id: lang_id)

    # **stdout / stderr のみ返す**
    render json: {
      stdout: result["stdout"] || "",
      stderr: result["stderr"] || ""
    }
  rescue Judge0::Error => e
    render json: { stdout: "", stderr: e.message }, status: :bad_gateway
  end

  # GET /pre_codes/:id/body
  def pre_code_body
    pc = PreCode.find(params[:id])
    render json: { id: pc.id, title: pc.title, body: pc.body }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "not found" }, status: :not_found
  end

  private

  def judge0
    @judge0 ||= Judge0::Client.new
  end

  def ensure_json!
    return if request.format.json?
    head :not_acceptable
  end
end
