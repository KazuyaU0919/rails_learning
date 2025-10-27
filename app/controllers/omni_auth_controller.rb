# ============================================================
# OmniAuthController
# ------------------------------------------------------------
# 外部認証（Google / GitHub）からのコールバックを処理。
# - callback: 連携 or ログイン or 新規作成
# - failure : 連携/ログイン失敗時のハンドラ
# ------------------------------------------------------------
# フロー（callback）:
#   1) 現ログイン中 + link=1  … 既存アカウントへ外部連携（メール一致を要求）
#   2) 既存認証レコードあり … ログイン
#   3) 同メールのユーザー … 認証レコードを紐付けてログイン
#   4) いずれも無い場合   … 新規ユーザー作成（ダミーパス付与）→ 連携 → ログイン
# 失敗時は new_session_path へリダイレクト
# ============================================================

class OmniAuthController < ApplicationController
  # コールバックのみ CSRF 免除（OmniAuthの仕組み上POSTを受けるため）
  protect_from_forgery except: :callback

  # OmniAuth の規定: /auth/:provider 以外の GET を404にする
  def passthru
    head :not_found
  end

  # =======================
  # コールバック
  # =======================
  def callback
    auth  = request.env["omniauth.auth"] || (raise "omniauth.auth is nil")
    prov  = auth.provider.to_s            # "google_oauth2" / "github"
    uid   = auth.uid.to_s
    info  = auth.info || OpenStruct.new
    email = info.email.to_s.downcase.presence
    name  = info.name.presence || info.nickname.presence || prov.titleize

    # ---- 1) ログイン中 + link=1 → 既存ユーザーに外部連携を追加 ----
    if current_user && params[:link].present?
      if Authentication.exists?(provider: prov, uid: uid)
        redirect_to edit_profile_path, alert: "このアカウントは既に他のユーザーに連携されています" and return
      end
      # セキュリティ: メールアドレス一致を要求（他者アカウント連携を防ぐ）
      if email.blank? || email.strip.downcase != current_user.email.to_s.strip.downcase
        redirect_to edit_profile_path, alert: "メールアドレスが違います" and return
      end
      current_user.authentications.create!(provider: prov, uid: uid)
      redirect_to profile_path, notice: "外部連携を設定しました" and return
    end

    # ---- 2) 認証レコードが既にある → そのユーザーでログイン ----
    if (authentication = Authentication.find_by(provider: prov, uid: uid))
      return user_login!(authentication.user, notice: "#{provider_label(prov)}でログインしました")
    end

    # ---- 3) 同メールのユーザーが存在 → 認証レコードを紐付けてログイン ----
    if email && (user = User.where("lower(email) = ?", email).first)
      user.authentications.find_or_create_by!(provider: prov, uid: uid)
      return user_login!(user, notice: "#{provider_label(prov)}をあなたのアカウントに連携しました")
    end

    # ---- 4) 上記に該当しない → 新規ユーザー作成 + 認証レコード作成 ----
    user = User.create!(
      name:     name,
      email:    email,
      password: SecureRandom.alphanumeric(16) # ★ 既存仕様: 6..19 の範囲内（ここでは16文字）
    )
    user.authentications.create!(provider: prov, uid: uid)
    user_login!(user, notice: "#{provider_label(prov)}で新規登録しました")

  rescue => e
    # 予期せぬ例外はエラーログのみ残してログイン画面へ
    Rails.logger.error("[OmniAuth #{e.class}] #{e.message}\n#{e.backtrace&.first}")
    redirect_to new_session_path, alert: "外部ログインに失敗しました"
  end

  # 失敗時（キャンセル/エラー）ハンドラ
  def failure
    redirect_to new_session_path, alert: "外部ログインがキャンセル/失敗しました"
  end

  private

  # =======================
  # ログイン処理の共通化
  # =======================
  def user_login!(user, notice:)
    reset_session
    session[:user_id] = user.id
    user.update_column(:last_login_at, Time.current)
    remember_if_needed!(user)
    # ※ 既存仕様から変更しないため、notice の渡し方も元のまま
    redirect_to root_path, notice:
  end

  # 「次回もログイン」の意図がある場合のみ Remember を保存
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

  # 表示ラベル
  def provider_label(provider)
    case provider
    when "google_oauth2" then "Google"
    when "github"        then "GitHub"
    else provider.to_s.titleize
    end
  end
end
