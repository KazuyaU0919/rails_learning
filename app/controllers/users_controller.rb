# ============================================================
# UsersController
# ------------------------------------------------------------
# 通常登録フォームと作成処理を担当（OmniAuth 経由は別コントローラ）。
# - new   : 登録フォーム表示（未ログインのみ）
# - create: ユーザー作成（成功でログイン状態に）
#
# エラーハンドリング：
#   - モデルバリデーション失敗時はフォーム再表示
#   - 重複メールは「既に登録済み」の扱いでログイン画面へ促す
#   - DB レベルの一意制約違反も同メッセージに統一
# ============================================================

class UsersController < ApplicationController
  before_action :require_guest!, only: %i[new create]
  before_action :use_gray_bg

  # =======================
  # 新規登録フォーム
  # =======================
  def new
    @user = User.new
  end

  # =======================
  # 登録実行
  # =======================
  def create
    @user = User.new(user_params) # provider なし → 通常登録

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "登録しました"
    else
      # モデル側に uniqueness が無い場合でも、下記の実在チェックで検出
      if email_taken_for_normal_signup?(@user)
        redirect_to new_session_path, alert: "そのメールアドレスは既に登録済みです。ログインしてください。"
      else
        flash.now[:alert] = "入力内容を確認してください"
        render :new, status: :unprocessable_entity
      end
    end

  rescue ActiveRecord::RecordNotUnique
    # DBレベルの競合も同じメッセージに統一
    redirect_to new_session_path, alert: "そのメールアドレスは既に登録済みです。ログインしてください。"
  end

  private

  # =======================
  # 表示設定（新規登録ページの背景色など）
  # =======================
  def use_gray_bg
    @body_bg = "bg-slate-50"
  end

  # =======================
  # Strong Parameters
  # =======================
  def user_params
    params.require(:user)
          .permit(:name, :email, :password, :password_confirmation)
  end

  # =======================
  # 重複メールの実在チェック
  #   - モデルの :taken エラーが付与されていれば true
  #   - 念のため DB にも照会（大文字小文字を無視）
  # =======================
  def email_taken_for_normal_signup?(user)
    return true if user.errors.added?(:email, :taken)

    email = user.email.to_s.downcase
    User.where("lower(email) = ?", email).exists?
  end
end
