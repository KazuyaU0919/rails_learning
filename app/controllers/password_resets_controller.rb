# ============================================================
# PasswordResetsController
# ------------------------------------------------------------
# パスワード再設定フロー（メール送信 → トークンから再設定）。
# - new / create : ゲスト専用（ユーザーの有無は秘匿）
# - edit / update: トークン保持者であればログイン有無に関係なく可
# ============================================================

class PasswordResetsController < ApplicationController
  # =======================
  # フィルタ
  # =======================
  # new/create は未ログインのみ。edit/update はトークン保持であればアクセス可
  before_action :require_guest!, only: %i[new create]
  # 画面の背景色を統一（UI目的）
  before_action :use_gray_bg

  # =======================
  # 画面
  # =======================
  def new; end

  # =======================
  # メール送信（公開フォーム）
  # -----------------------
  # 仕様:
  # - 入力メールに一致するユーザーがいれば、外部連携の有無に関わらず送信。
  # - 応答メッセージはユーザーの有無を秘匿。
  # - dev/test では「非送信理由」を info ログに出す（prod は秘匿）。
  # =======================
  def create
    email = params[:email].to_s.strip.downcase
    user  = User.find_by(email: email)

    if user
      user.generate_reset_token!                  # トークン発行
      UserMailer.reset_password(user).deliver_later # 非同期送信（dev は inline）
      Rails.logger.info("[PasswordResets] enqueued reset mail user_id=#{user.id} uses_password=#{user.uses_password?}")
    else
      Rails.logger.info("[PasswordResets] no user for email=#{email} (mail not sent)") unless Rails.env.production?
    end

    # ユーザー存在の有無は秘匿する応答
    redirect_to root_path, notice: "該当メールへパスワード再設定用のメールを送信しました（該当メールが存在する場合）"
  end

  # =======================
  # 再設定フォーム
  # -----------------------
  # - @user: トークンで対象ユーザーを特定（期限切れは弾く）
  # =======================
  def edit
    @user = User.find_by(reset_password_token: params[:id]) # :id = token
    unless @user&.reset_token_valid?
      redirect_to new_password_reset_path, alert: "トークンが無効です"
    end
  end

  # =======================
  # 再設定実行
  # -----------------------
  # - 成功時: トークン破棄 & Remember 全無効化 & セッション/クッキー掃除
  # =======================
  def update
    @user = User.find_by(reset_password_token: params[:id])
    unless @user&.reset_token_valid?
      return redirect_to new_password_reset_path, alert: "トークンが無効です"
    end

    if @user.update(password_params)
      # 使用済トークンの破棄 & Remember情報の無効化（他端末ログアウト）
      @user.clear_reset_token!
      @user.revoke_all_remember!
      cookies.delete(:remember_me, same_site: :lax, secure: Rails.env.production?)
      reset_session
      redirect_to new_session_path, notice: "パスワードを更新しました。ログインしてください"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # =======================
  # Strong Parameters
  # =======================
  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  # 背景色（view 側で使用）
  def use_gray_bg
    @body_bg = "bg-slate-50"
  end
end
