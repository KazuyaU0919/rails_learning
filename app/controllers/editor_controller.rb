# ============================================================
# EditorController
# ------------------------------------------------------------
# ブラウザ上のコード実行エディタ画面と、その実行API/補助APIを提供。
# - index: エディタ画面（自分の投稿/ブックマークをサイドから選択）
# - create: コードの実行（Judge0 API）
# - pre_code_body: PreCode 1件の本文/解説などをエディタ向けJSONで返却
# ------------------------------------------------------------
# ポイント
# - JSONエンドポイントはリクエスト形式を JSON に限定（ensure_json!）
# - コード実行は制御文字の混入や最大バイト数をチェック
# - HTMLの返却部分はサニタイズして安全性を担保
# ============================================================

class EditorController < ApplicationController
  # =======================
  # フィルタ / CSRF
  # =======================
  # JSON 以外は弾く（create / pre_code_body のみ）
  before_action :ensure_json!, only: %i[create pre_code_body]
  # 実行APIはJSON専用のため、ここだけ null_session（以外は通常のCSRF対策）
  protect_from_forgery with: :null_session, only: :create

  # =======================
  # 定数（バリデーション系）
  # =======================
  # 制御文字（NULL〜US, DEL 等）を禁止
  FORBIDDEN_CTRL_RE = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/.freeze
  # コード最大バイト数（既存仕様）
  MAX_CODE_BYTES = 200_000

  # =======================
  # 画面
  # =======================
  # GET /editor
  # - ログイン済み: 自分の PreCode と、ブックマーク済みの他人の PreCode を表示用に取得
  # - 未ログイン: 空
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

  # =======================
  # API: コード実行
  # =======================
  # POST /editor
  # 期待パラメータ:
  #   - code (String)
  #   - language_id (任意; 省略で Ruby)
  # レスポンス: { stdout: String, stderr: String }
  def create
    code    = params[:code].to_s
    lang_id = params[:language_id].presence || Judge0::Client::RUBY_LANG_ID

    # 入力バリデーション
    if code.strip.empty?
      render json: { stdout: "", stderr: I18n.t!("editor.errors.blank") }, status: :unprocessable_entity and return
    end
    if code.bytesize > MAX_CODE_BYTES
      render json: { stdout: "", stderr: I18n.t!("editor.errors.too_large") }, status: :unprocessable_entity and return
    end
    if code.match?(FORBIDDEN_CTRL_RE)
      render json: { stdout: "", stderr: I18n.t!("editor.errors.forbidden_chars") }, status: :unprocessable_entity and return
    end

    # 実行（Judge0 クライアントに委譲）
    result = Judge0::Client.new.run_ruby(code, language_id: lang_id)
    render json: { stdout: result["stdout"] || "", stderr: result["stderr"] || "" }
  rescue Judge0::Error => e
    # Judge0 側の失敗は 502 相当で返す
    render json: { stdout: "", stderr: e.message }, status: :bad_gateway
  end

  # =======================
  # API: PreCode本文の取得（エディタ向け）
  # =======================
  # GET /pre_codes/:id/body
  # - 「問題モード」判定も同時に返却（ヒント/解答/解答コードいずれかの有無）
  def pre_code_body
    pc = PreCode.find(params[:id])

    # 「問題モード」判定：answer/answer_code どちらかがあれば true
    is_quiz = pc.answer.present? || pc.answer_code.present?

    # 返却HTMLは限定タグのみ許可してサニタイズ
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

  # =======================
  # リクエスト形式の制限
  # =======================
  def ensure_json!
    return if request.format.json?
    head :not_acceptable
  end
end
