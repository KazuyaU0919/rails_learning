# app/controllers/omni_auth_controller.rb
class OmniAuthController < ApplicationController
  # OmniAuthは外部リダイレクト→callbackのみCSRF除外
  protect_from_forgery except: :callback

  # /auth/:provider に直アクセスされた時の穴埋め（Rackが処理するので通常来ない）
  def passthru
    head :not_found
  end

  def callback
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_omniauth(auth)  # ← Userモデルに用意済みメソッド
    reset_session
    session[:user_id] = user.id

    provider_name = auth.provider.to_s.titleize
    redirect_to root_path, notice: "#{provider_name}でログインしました"
  rescue => e
    Rails.logger.error("[OmniAuth] #{e.class}: #{e.message}\n#{e.backtrace&.first}")
    redirect_to new_session_path, alert: "外部ログインに失敗しました"
  end

  def failure
    redirect_to new_session_path, alert: "外部ログインがキャンセル/失敗しました"
  end
end
