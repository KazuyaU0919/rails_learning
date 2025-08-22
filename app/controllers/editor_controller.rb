# app/controllers/editor_controller.rb
class EditorController < ApplicationController
  # MVP: axios で JSON を投げる想定（CSRF トークンを付ける版に切替予定なら後で外す）
  protect_from_forgery with: :null_session, only: :create

  # GET /editor (root)
  def index
    @my_pre_codes   = logged_in? ? current_user.pre_codes.order(created_at: :desc).limit(30) : PreCode.none
    @popular_public = PreCode.order(like_count: :desc).limit(30)
  end

  # POST /editor
  # params: { code: "puts 1+1", language_id: 72 }
  def create
    code = params[:code].to_s

    # ParameterMissing を起こさず 422 を返す
    if code.strip.empty?
      render json: { error: "code が空です" }, status: :unprocessable_entity
      return
    end

    # サイズ制限
    if code.bytesize > 200_000
      render json: { error: "code が長すぎます" }, status: :unprocessable_entity
      return
    end

    lang_id = params[:language_id].presence || Judge0::Client::RUBY_LANG_ID
    result  = Judge0::Client.new.run_ruby(code, language_id: lang_id)

    render json: {
      status: result.dig("status", "description"),
      stdout: result["stdout"],
      stderr: result["stderr"],
      time:   result["time"],
      memory: result["memory"],
      token:  result["token"] # デバッグ/将来の参照用
    }
  rescue Judge0::Error => e
    # メッセージ内に "HTTP 4xx" が含まれていれば、そのコードで返す
    if (m = e.message.match(/HTTP\s+(\d{3})/))
      render json: { error: e.message }, status: m[1].to_i
    else
      render json: { error: e.message }, status: :bad_gateway
    end
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
end
