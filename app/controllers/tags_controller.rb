# app/controllers/tags_controller.rb
class TagsController < ApplicationController
  # インクリメンタル候補（従来どおり使用中のみ）
  def index
    @tags = Tag.used.prefix(params[:query]).order_for_suggest.limit(20)
    respond_to do |f|
      f.html { redirect_to root_path }
      f.json { render json: @tags.as_json(only: [ :id, :name, :slug, :color, :taggings_count ]) }
    end
  end

  # タグピッカー用：未使用も含めて人気順（利用数降順、name_norm昇順）
  def popular
    rel = Tag.order(taggings_count: :desc, name_norm: :asc)
    rel = rel.where("name_norm LIKE ?", "#{Tag.normalize(params[:q])}%") if params[:q].present?
    @tags = rel.limit(200)
    render json: @tags.as_json(only: [ :id, :name, :slug, :color, :taggings_count ])
  end

  # 新規タグ作成（JSON）
  def create
    name = params.require(:tag).permit(:name)[:name]
    tag  = Tag.find_by(name_norm: Tag.normalize(name)) || Tag.create!(name: name)
    render json: tag.as_json(only: [ :id, :name, :slug, :color, :taggings_count ]), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end

  # 既存
  def show
    @tag = Tag.find_by!(slug: params[:id])
    redirect_to pre_codes_path(tags: @tag.name)
  end
end
