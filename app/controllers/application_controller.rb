# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  helper_method :current_user, :logged_in?

  rescue_from ActiveRecord::RecordNotFound do
    respond_to do |f|
      # HTMLアクセス時 → public/404.html を返す
      f.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      # JSONアクセス時 → JSONエラーメッセージを返す
      f.json { render json: { error: "not found" }, status: :not_found }
    end
  end

  private

  def current_user
    # ① 通常セッションから取得
    if session[:user_id].present?
      @current_user ||= User.find_by(id: session[:user_id])
      return @current_user if @current_user
    end

    # ② Rememberクッキーから自動復帰
    if cookies.encrypted[:remember_me].present?
      payload = cookies.encrypted[:remember_me] # { "user_id" => ..., "token" => ... }
      user = User.find_by(id: payload["user_id"])

      if user && user.authenticated_remember?(payload["token"]) && !user.remember_expired?
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

  def logged_in?
    current_user.present?
  end

  # 認証が必要な画面
  def require_login!
    return if logged_in?
    redirect_to new_session_path, alert: "ログインしてください"
  end

  # すでにログインしているなら来てほしくない画面（ログイン/登録/パス再送など）
  def require_guest!
    return unless logged_in?
    redirect_to root_path, alert: "すでにログイン済みです"
  end

  # CSRFトークンエラー時のハンドリング（任意）
  def handle_bad_csrf
    reset_session
    redirect_to new_session_path, alert: "セッションが切れました。もう一度ログインしてください"
  end
end
