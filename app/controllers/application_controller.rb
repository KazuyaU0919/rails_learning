# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  helper_method :current_user, :logged_in?

  rescue_from ActiveRecord::RecordNotFound do
    # 本番は既定で 404 HTML を返します。開発でも同じにしたいなら:
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
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
