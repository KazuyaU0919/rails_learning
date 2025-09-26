# app/controllers/omni_auth_controller.rb
class OmniAuthController < ApplicationController
  protect_from_forgery except: :callback

  def passthru
    head :not_found
  end

  def callback
    auth   = request.env["omniauth.auth"] || (raise "omniauth.auth is nil")
    prov   = auth.provider.to_s          # "google_oauth2" or "github"
    uid    = auth.uid.to_s
    info   = auth.info || OpenStruct.new
    email  = info.email.to_s.downcase.presence
    name   = info.name.presence || info.nickname.presence || prov.titleize

    # === ① プロフィールからの「接続」か？（link=1 を見て判定） ===
    if current_user && params[:link].present?
      # 他ユーザーに同じ provider+uid が無いか
      if Authentication.exists?(provider: prov, uid: uid)
        redirect_to edit_profile_path, alert: "このアカウントは既に他のユーザーに連携されています" and return
      end

      # メール完全一致のみ許可
      if email.blank? || email.strip.downcase != current_user.email.to_s.strip.downcase
        redirect_to edit_profile_path, alert: "メールアドレスが違います" and return
      end

      current_user.authentications.create!(provider: prov, uid: uid)
      redirect_to profile_path, notice: "外部連携を設定しました" and return
    end

    # === ② 通常のログインフロー（既存実装） ===
    authentication = Authentication.find_by(provider: prov, uid: uid)
    if authentication
      user = authentication.user
      reset_session
      session[:user_id] = user.id
      user.update_column(:last_login_at, Time.current)
      redirect_to root_path, notice: "#{provider_label(prov)}でログインしました" and return
    end

    if email && (user = User.where("lower(email) = ?", email).first)
      user.authentications.find_or_create_by!(provider: prov, uid: uid)
      reset_session
      session[:user_id] = user.id
      user.update_column(:last_login_at, Time.current)
      redirect_to root_path, notice: "#{provider_label(prov)}をあなたのアカウントに連携しました" and return
    end

    # 新規ユーザー作成（ダミーパスワード）
    user = User.create!(
      name:     name,
      email:    email,
      password: SecureRandom.urlsafe_base64(24)
    )
    user.authentications.create!(provider: prov, uid: uid)
    reset_session
    session[:user_id] = user.id
    user.update_column(:last_login_at, Time.current)
    redirect_to root_path, notice: "#{provider_label(prov)}で新規登録しました"

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
