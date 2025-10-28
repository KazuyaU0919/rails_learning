# ============================================================
# TagsController
# ------------------------------------------------------------
# タグ関連の取得・作成・リダイレクトを担当。
# 用途ごとに2系統の取得APIを提供する：
#   1) index   : 旧来の「使用中タグのみ」からのインクリメンタル候補
#   2) popular : タグピッカー用（未使用タグも含め、人気順＋プレフィックス検索）
#
# さらに、タグ新規作成（JSON）と、/tags/:id への SEO 互換 show も提供。
# ============================================================

class TagsController < ApplicationController
  # =======================
  # 1) 旧来のサジェスト（使用中のみ）
  #    - params[:query] の前方一致（name_norm の prefix）
  #    - used スコープで「使用中」だけを対象
  # =======================
  def index
    @tags = Tag.used
               .prefix(params[:query])
               .order_for_suggest
               .limit(20)

    respond_to do |f|
      f.html { redirect_to root_path } # HTMLアクセスはトップへ
      f.json { render json: @tags.as_json(only: [ :id, :name, :slug, :color, :taggings_count ]) }
    end
  end

  # =======================
  # 2) タグピッカー用API（未使用含む）
  #    - 人気順（taggings_count DESC, name_norm ASC）
  #    - params[:q] があれば name_norm の prefix フィルタ
  #    - 上限 200件（クライアントでのインタラクション前提）
  # =======================
  def popular
    rel = Tag.order(taggings_count: :desc, name_norm: :asc)
    rel = rel.where("name_norm LIKE ?", "#{Tag.normalize(params[:q])}%") if params[:q].present?
    @tags = rel.limit(200)

    render json: @tags.as_json(only: [ :id, :name, :slug, :color, :taggings_count ])
  end

  # =======================
  # 3) 新規タグ作成（JSON）
  #    - name を受け取り、正規化 name_norm で既存検索 → なければ作成
  #    - 成功時 201 Created / 失敗時 422 Unprocessable Entity
  # =======================
  def create
    name = params.require(:tag).permit(:name)[:name]
    tag  = Tag.find_by(name_norm: Tag.normalize(name)) || Tag.create!(name: name)

    render json: tag.as_json(only: [ :id, :name, :slug, :color, :taggings_count ]),
           status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(", ") },
           status: :unprocessable_entity
  end

  # =======================
  # 4) 既存SEO互換：/tags/:id を /pre_codes にリダイレクト
  #    - :id には slug が渡ってくる
  # =======================
  def show
    @tag = Tag.find_by!(slug: params[:id])
    redirect_to pre_codes_path(tags: @tag.name)
  end
end
