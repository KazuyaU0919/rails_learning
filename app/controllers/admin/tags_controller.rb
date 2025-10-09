# app/controllers/admin/tags_controller.rb
class Admin::TagsController < Admin::BaseController
  layout "admin"

  def index
    @q = params[:q].to_s
    # 未使用も含めて一覧表示（used を外す）
    @tags = Tag.prefix(@q).order_for_suggest.page(params[:page])
  end

  def merge
    from = Tag.find(params[:from_id]); to = Tag.find(params[:to_id])
    raise ActiveRecord::RecordInvalid, "同一タグへは統合できません" if from.id == to.id

    Tag.transaction do
      PreCodeTagging.where(tag_id: from.id).update_all(tag_id: to.id)
      # 重複排除
      PreCodeTagging.group(:pre_code_id, :tag_id).having("COUNT(*) > 1").pluck(:pre_code_id, :tag_id).each do |pid, tid|
        PreCodeTagging.where(pre_code_id: pid, tag_id: tid).offset(1).delete_all
      end
      # カウンタ再計算
      Tag.reset_counters(to.id, :pre_code_taggings)
      Tag.reset_counters(from.id, :pre_code_taggings)
      from.destroy! if from.taggings_count.zero?
    end
    redirect_to admin_tags_path, notice: "統合しました"
  end

  def destroy
    tag = Tag.find(params[:id])
    return redirect_to admin_tags_path, alert: "使用中のタグは削除できません" unless tag.taggings_count.zero?
    tag.destroy!
    redirect_to admin_tags_path, notice: "削除しました"
  end
end
