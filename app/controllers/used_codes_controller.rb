# ============================================================
# UsedCodesController
# ------------------------------------------------------------
# 「使ってみた」記録（UsedCode）を作成するだけのエンドポイント。
# - 同一ユーザーが短時間に連投した場合は簡易スロットル（3秒）で無視。
# - counter_cache（PreCode#use_count）を更新するためのレコード。
# - 自分の投稿には使えない（:forbidden）。
# ============================================================

class UsedCodesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: :create

  # =======================
  # 作成（POST /used_codes）
  # =======================
  def create
    # 自分の投稿は弾く（自己加算防止）
    return head :forbidden if @pre_code.user_id == current_user.id

    # ---- 連打の簡易スロットル（3秒以内の連続送信は無視）----
    recently = UsedCode
                 .where(user: current_user, pre_code: @pre_code)
                 .where("created_at > ?", 3.seconds.ago)
                 .exists?

    unless recently
      # レコードを1件作るだけで counter_cache(:use_count) が +1 される
      UsedCode.create!(user: current_user, pre_code: @pre_code, used_at: Time.current)
    end

    # 最新値に更新（ビュー側で use_count を正しく表示するため）
    @pre_code.reload

    # 同期リダイレクト（パラメータで来ていればエディタ、無ければ一覧）
    redirect_to params[:redirect].presence || code_libraries_path
  end

  private

  # =======================
  # 共通セットアップ
  # =======================
  def set_pre_code
    @pre_code = PreCode.find(params[:pre_code_id])
  end
end
