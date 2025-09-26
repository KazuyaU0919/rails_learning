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

    # === ② 通常のログインフロー（成功時は Remember を適用） ===
    if (authentication = Authentication.find_by(provider: prov, uid: uid))
      return user_login!(authentication.user,
                         notice: "#{provider_label(prov)}でログインしました")
    end

    if email && (user = User.where("lower(email) = ?", email).first)
      user.authentications.find_or_create_by!(provider: prov, uid: uid)
      return user_login!(user,
                         notice: "#{provider_label(prov)}をあなたのアカウントに連携しました")
    end

    # 新規ユーザー作成（ダミーパスワード）
    user = User.create!(
      name:     name,
      email:    email,
      password: SecureRandom.urlsafe_base64(24)
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

  # 成功時の共通処理（セッション確立 + last_login_at 更新 + Remember 適用 + リダイレクト）
  def user_login!(user, notice:)
    reset_session
    session[:user_id] = user.id
    user.update_column(:last_login_at, Time.current)
    remember_if_needed!(user) # ★ 追加：Remember対応
    redirect_to root_path, notice:
  end

  # 「ログイン状態を保持する」選択時に Remember クッキーを発行
  # - params[:remember] == "1" … パスワード/外部ログイン共通の即時指定
  # - cookies.encrypted[:remember_intent] == "1" … /auth/:provider に遷移する前に仕込んでおくワンショット意図
  def remember_if_needed!(user)
    return unless params[:remember] == "1" || cookies.encrypted[:remember_intent] == "1"

    token = user.remember! # user側で digest 保存 & トークン発行する想定

    cookies.encrypted[:remember_me] = {
      value:    { user_id: user.id, token: token },
      expires:  30.days,
      httponly: true,
      secure:   Rails.env.production?,
      same_site: :lax
    }

    # ワンショットの意図フラグは使い切り
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
