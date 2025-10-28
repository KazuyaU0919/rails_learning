# ============================================================
# BookmarksController
# ------------------------------------------------------------
# ユーザーによる PreCode のブックマーク機能。
# ------------------------------------------------------------
# 主な責務：
#   - ブックマーク登録/解除
#   - 自身の投稿ブックマーク禁止
#   - 上限数（300件）の制御
#   - Turbo Stream / HTML 両対応
# ============================================================

class BookmarksController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: :create

  # =======================
  # 登録
  # =======================
  def create
    # 自分の投稿はブックマーク不可
    return head :forbidden if @pre_code.user_id == current_user.id

    # 上限チェック
    if current_user.bookmarks.count >= 300
      redirect_back fallback_location: code_libraries_path,
                    alert: I18n.t("bookmarks.limit_reached") and return
    end

    # 登録（重複時は rescue）
    current_user.bookmarks.create!(pre_code: @pre_code)
    @pre_code.reload

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  rescue ActiveRecord::RecordInvalid
    head :ok # 既存などで無視
  end

  # =======================
  # 解除
  # =======================
  def destroy
    bookmark = current_user.bookmarks.find(params[:id])
    @pre_code = bookmark.pre_code
    bookmark.destroy!
    @pre_code.reload

    respond_to do |f|
      f.turbo_stream
      f.html { redirect_back fallback_location: code_libraries_path }
    end
  end

  private

  def set_pre_code
    @pre_code = PreCode.find(params[:pre_code_id])
  end
end
