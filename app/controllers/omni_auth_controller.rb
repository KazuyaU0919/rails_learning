# app/controllers/omni_auth_controller.rb
class OmniAuthController < ApplicationController
  # 外部→callback だけ CSRF 除外（既存仕様を維持）
  protect_from_forgery except: :callback

  # /auth/:provider に直アクセスされたときの穴埋め
  def passthru
    head :not_found
  end

  # /auth/:provider/callback
  def callback
    auth = request.env["omniauth.auth"] or raise "omniauth.auth is nil"

    provider  = auth.provider.to_s            # "google_oauth2" / "github"
    uid       = auth.uid.to_s
    info      = auth.info || OpenStruct.new
    email     = info.email.to_s.downcase.presence
    display   = provider_label(provider)
    name      = info.name.presence || email&.split("@")&.first || "#{provider}_user"

    # 1) 既存の認証レコードがある → そのユーザーでログイン
    if (authentication = Authentication.find_by(provider: provider, uid: uid))
      user = authentication.user
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "#{display}でログインしました" and return
    end

    # 2) 認証レコードは無いが同じメールのユーザーがいる → 既存ユーザーに紐付け
    if email && (user = User.where("lower(email) = ?", email).first)
      user.authentications.find_or_create_by!(provider: provider, uid: uid)
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "#{display}をあなたのアカウントに連携しました" and return
    end

    # 3) どちらも無ければ新規作成（パスワードはダミー）
    user = User.create!(
      name:     name,
      email:    email,  # 一部プロバイダは nil の可能性あり
      password: SecureRandom.urlsafe_base64(24)
    )
    user.authentications.create!(provider: provider, uid: uid)

    reset_session
    session[:user_id] = user.id
    redirect_to root_path, notice: "#{display}で新規登録しました"

  rescue => e
    Rails.logger.error("[OmniAuth #{e.class}] #{e.message}\n#{e.backtrace&.first}")
    redirect_to new_session_path, alert: "外部ログインに失敗しました"
  end

  def failure
    redirect_to new_session_path, alert: "外部ログインがキャンセル/失敗しました"
  end

  private

  def provider_label(provider)
    case provider
    when "google_oauth2" then "Google"
    when "github"        then "GitHub"
    else provider.to_s.titleize
    end
  end
end
