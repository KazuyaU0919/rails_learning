# ============================================================
# ApplicationController
# ------------------------------------------------------------
# 全コントローラの基底クラス。
# 共通のヘルパー、エラーハンドリング、認証補助メソッドを提供。
# ------------------------------------------------------------
# 主な責務：
#   - current_user / logged_in? の提供
#   - セッション or Rememberクッキーによるログイン継続
#   - ログイン必須/禁止の画面制御
#   - ActiveRecord::RecordNotFound の例外処理
#   - CSRFトークン異常時のハンドリング
# ============================================================

class ApplicationController < ActionController::Base
  # モダンブラウザ限定（Gem: browser）
  allow_browser versions: :modern

  # ビューでも使えるようにする
  helper_method :current_user, :logged_in?

  # PaperTrail (監査用Gem) の whodunnit 設定
  before_action :set_paper_trail_whodunnit

  # =======================
  # 例外ハンドリング
  # =======================
  rescue_from ActiveRecord::RecordNotFound do
    respond_to do |f|
      # HTMLアクセス → public/404.html
      f.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      # JSONアクセス → JSONレスポンス
      f.json { render json: { error: "not found" }, status: :not_found }
    end
  end

  private

  # =======================
  # 認証系ヘルパー
  # =======================

  # 現在のユーザーを返す（セッション or Rememberクッキー）
  def current_user
    # ① 通常セッションから取得
    if session[:user_id].present?
      @current_user ||= User.find_by(id: session[:user_id])
      return @current_user if @current_user
    end

    # ② Rememberクッキーから自動復帰
    if cookies.encrypted[:remember_me].present?
      payload = cookies.encrypted[:remember_me] # => { "user_id" => ..., "token" => ... }
      user = User.find_by(id: payload["user_id"])

      if user && user.authenticated_remember?(payload["token"]) && !user.remember_expired?
        # 有効なトークン → セッション再発行＋ログイン再構築
        reset_session
        session[:user_id] = user.id
        user.update_column(:last_login_at, Time.current)
        @current_user = user
      else
        # トークン期限切れ/不一致 → クッキー破棄
        cookies.delete(:remember_me, same_site: :lax, secure: Rails.env.production?)
      end
    end

    @current_user
  end

  # ログイン状態確認
  def logged_in?
    current_user.present?
  end

  # =======================
  # アクセス制御
  # =======================

  # ログイン必須ページ
  def require_login!
    return if logged_in?
    redirect_to new_session_path, alert: "ログインしてください"
  end

  # ゲスト専用ページ（ログイン済みはアクセス不可）
  def require_guest!
    return unless logged_in?
    redirect_to root_path, alert: "すでにログイン済みです"
  end

  # =======================
  # CSRFエラー時の対応（任意）
  # =======================
  def handle_bad_csrf
    reset_session
    redirect_to new_session_path, alert: "セッションが切れました。もう一度ログインしてください"
  end
end
