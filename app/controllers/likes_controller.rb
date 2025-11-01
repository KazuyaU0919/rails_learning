# ============================================================
# LikesController
# ------------------------------------------------------------
# PreCode に対する「いいね」作成/削除を扱う。
# - create: 自分以外の PreCode にいいね
# - destroy: 自分が付けたいいねを外す
# ------------------------------------------------------------
# ポイント
# - ログイン必須
# - 自分の投稿にはいいね不可
# - Turbo Stream / HTML のハイブリッド応答
# ============================================================

class LikesController < ApplicationController
  # =======================
  # フィルタ
  # =======================
  before_action :require_login!
  before_action :set_pre_code, only: [ :create, :destroy ]

  # =======================
  # いいね作成
  # =======================
  def create
    # 自分の投稿は不可
    return head :forbidden if @pre_code.user_id == current_user.id

    current_user.likes.create!(pre_code: @pre_code)

    @pre_code.reload
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  rescue ActiveRecord::RecordInvalid
    # 既に付与済み等、バリデーション失敗は 200 で黙殺
    head :ok
  end

  # =======================
  # いいね削除
  # =======================
  def destroy
    like = current_user.likes.find(params[:id])
    @pre_code = like.pre_code
    like.destroy!

    @pre_code.reload
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  end

  private

  # =======================
  # 共通取得
  # =======================
  def set_pre_code
    @pre_code =
      if params[:pre_code_id].present?
        # create 時: 明示的に pre_code_id が来る想定
        PreCode.find(params[:pre_code_id])
      else
        # destroy 時: :id で Like → そこから対象 PreCode を辿る保険
        current_user.likes.find(params[:id]).pre_code
      end
  end
end
