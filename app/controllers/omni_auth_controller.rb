# app/controllers/omni_auth_controller.rb
class OmniAuthController < ApplicationController
  protect_from_forgery except: :callback

  def passthru
    head :not_found
  end

  def callback
    auth  = request.env["omniauth.auth"] || (raise "omniauth.auth is nil")
    prov  = auth.provider.to_s            # "google_oauth2" / "github"
    uid   = auth.uid.to_s
    info  = auth.info || OpenStruct.new
    email = info.email.to_s.downcase.presence
    name  = info.name.presence || info.nickname.presence || prov.titleize

    # ① アカウント接続（ログイン済み + link=1）
    if current_user && params[:link].present?
      if Authentication.exists?(provider: prov, uid: uid)
        redirect_to edit_profile_path, alert: "このアカウントは既に他のユーザーに連携されています" and return
      end
      if email.blank? || email.strip.downcase != current_user.email.to_s.strip.downcase
        redirect_to edit_profile_path, alert: "メールアドレスが違います" and return
      end
      current_user.authentications.create!(provider: prov, uid: uid)
      redirect_to profile_path, notice: "外部連携を設定しました" and return
    end

    # ② 通常ログイン
    if (authentication = Authentication.find_by(provider: prov, uid: uid))
      return user_login!(authentication.user, notice: "#{provider_label(prov)}でログインしました")
    end

    if email && (user = User.where("lower(email) = ?", email).first)
      user.authentications.find_or_create_by!(provider: prov, uid: uid)
      return user_login!(user, notice: "#{provider_label(prov)}をあなたのアカウントに連携しました")
    end

    # 新規ユーザー作成（★ 16文字のダミーパス）
    user = User.create!(
      name:     name,
      email:    email,
      password: SecureRandom.alphanumeric(16) # ← 6..19 の範囲内に修正
    )
    user.authentications.create!(provider: prov, uid: uid)
    user_login!(user, notice: "#{provider_label(prov)}で新規登録しました")

  rescue => e
    Rails.logger.error("[OmniAuth #{e.class}] #{e.message}\n#{e.backtrace&.first}")
    redirect_to new_session_path, alert: "外部ログインに失敗しました"
  end

  def failure
    redirect_to new_session_path, alert: "外部ログインがキャンセル/失敗しました"
  end

  private

  def user_login!(user, notice:)
    reset_session
    session[:user_id] = user.id
    user.update_column(:last_login_at, Time.current)
    remember_if_needed!(user)
    redirect_to root_path, notice:
  end

  def remember_if_needed!(user)
    return unless params[:remember] == "1" || cookies.encrypted[:remember_intent] == "1"

    token = user.remember!
    cookies.encrypted[:remember_me] = {
      value:     { user_id: user.id, token: token },
      expires:   30.days,
      httponly:  true,
      secure:    Rails.env.production?,
      same_site: :lax
    }
    cookies.delete(:remember_intent, same_site: :lax, secure: Rails.env.production?)
  end

  def provider_label(provider)
    case provider
    when "google_oauth2" then "Google"
    when "github"        then "GitHub"
    else provider.to_s.titleize
    end
  end
end
