# app/controllers/tags_controller.rb
class TagsController < ApplicationController
  def index
    # 候補API: /tags.json?query=ru
    @tags = Tag.used.prefix(params[:query]).order_for_suggest.limit(20)
    respond_to do |f|
      f.html { redirect_to root_path } # 画面不要
      f.json { render json: @tags.as_json(only: [ :id, :name, :slug, :color ]) }
    end
  end

  def show
    @tag = Tag.find_by!(slug: params[:id])
    redirect_to pre_codes_path(tags: @tag.name) # 既存一覧を流用
  end
end
