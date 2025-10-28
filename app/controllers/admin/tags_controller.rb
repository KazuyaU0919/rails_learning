# ============================================================
# 管理: タグ (Tag)
# ------------------------------------------------------------
# ・タグ一覧表示、統合、削除
# ・PreCodeTagging 経由でタグを他に統合
# ・未使用タグも一覧対象に含める
# ============================================================
class Admin::TagsController < Admin::BaseController
  layout "admin"

  # =======================
  # 一覧
  # =======================
  def index
    @q = params[:q].to_s
    @tags = Tag.prefix(@q).order_for_suggest.page(params[:page])
  end

  # =======================
  # 統合処理
  # -----------------------
  # from_id のタグを to_id へ移動。
  # PreCodeTagging を更新し重複排除。
  # =======================
  def merge
    from = Tag.find(params[:from_id])
    to   = Tag.find(params[:to_id])
    raise ActiveRecord::RecordInvalid, "同一タグへは統合できません" if from.id == to.id

    Tag.transaction do
      PreCodeTagging.where(tag_id: from.id).update_all(tag_id: to.id)

      # 重複 PreCodeTagging を削除
      PreCodeTagging.group(:pre_code_id, :tag_id)
                    .having("COUNT(*) > 1")
                    .pluck(:pre_code_id, :tag_id)
                    .each do |pid, tid|
                      PreCodeTagging.where(pre_code_id: pid, tag_id: tid).offset(1).delete_all
                    end

      # カウンタ再計算
      Tag.reset_counters(to.id, :pre_code_taggings)
      Tag.reset_counters(from.id, :pre_code_taggings)
      from.destroy! if from.taggings_count.zero?
    end

    redirect_to admin_tags_path, notice: "統合しました"
  end

  # =======================
  # 削除
  # =======================
  def destroy
    tag = Tag.find(params[:id])
    return redirect_to admin_tags_path, alert: "使用中のタグは削除できません" unless tag.taggings_count.zero?

    tag.destroy!
    redirect_to admin_tags_path, notice: "削除しました"
  end
end
