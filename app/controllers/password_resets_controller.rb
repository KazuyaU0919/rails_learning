# ============================================================
# PasswordResetsController
# ------------------------------------------------------------
# パスワード再設定フロー（メール送信 → トークンから再設定）。
# - new / create : ゲスト専用（外部連携の無いユーザーのみ対象）
# - edit / update: トークン保持者であればログイン有無に関係なく可
# ------------------------------------------------------------
# ポイント
# - メール送信は「該当メールが存在する場合のみ送る」だが、存在を秘匿する応答文
# - 再設定成功時は Remember トークンもすべて無効化
# - 背景色を薄グレーにするための view 用フラグ（use_gray_bg）
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
  # メール送信
  # =======================
  def create
    # 通常ユーザー（外部連携なし）のみを対象にした「パスワード忘れた？」導線
    user = User.where.missing(:authentications).find_by(email: params[:email])
    if user
      user.generate_reset_token!
      UserMailer.reset_password(user).deliver_later
    end
    # ユーザー存在の有無は秘匿する応答
    redirect_to root_path, notice: "該当メールへパスワード再設定用のメールを送信しました（該当メールが存在する場合）"
  end

  # =======================
  # 再設定フォーム
  # =======================
  def edit
    @user = User.find_by(reset_password_token: params[:id]) # :id = token
    unless @user&.reset_token_valid?
      redirect_to new_password_reset_path, alert: "トークンが無効です"
    end
  end

  # =======================
  # 再設定実行
  # =======================
  def update
    @user = User.find_by(reset_password_token: params[:id])
    unless @user&.reset_token_valid?
      return redirect_to new_password_reset_path, alert: "トークンが無効です"
    end

    # トークン保持者なら（外部認証ユーザー含め）誰でも更新可
    if @user.update(password_params)
      # 使用済トークンの破棄 & Remember情報の無効化
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
