# app/controllers/pre_codes_controller.rb
class PreCodesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: %i[show edit update destroy]

  # GET /pre_codes
  def index
    base = current_user.pre_codes

    # --- タグ AND フィルタ ---
    if params[:tags].present?
      tag_keys = parse_tags(params[:tags]) # "ruby,array" or ["ruby","array"]
      norm_keys = tag_keys.map { |n| normalize_tag(n) }.uniq

      if norm_keys.any?
        tag_ids = Tag.where(name_norm: norm_keys).pluck(:id)
        base =
          if tag_ids.any?
            # AND 検索：選んだタグ数と一致するまで group/having
            base.joins(:tags)
                .where(tags: { id: tag_ids })
                .group("pre_codes.id")
                .having("COUNT(DISTINCT tags.id) = ?", tag_ids.size)
          else
            base.none
          end
      end
    end

    @q = base.ransack(params[:q])
    @pre_codes = @q.result.order(id: :desc).page(params[:page])
  end

  # GET /pre_codes/:id
  def show; end

  # GET /pre_codes/new
  def new
    @pre_code = current_user.pre_codes.build
  end

  # POST /pre_codes
  def create
    @pre_code = current_user.pre_codes.build(pre_code_params)
    if @pre_code.save
      replace_tags(@pre_code, params[:tag_names]) # ★ タグ付与
      redirect_to @pre_code, notice: "PreCode を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /pre_codes/:id/edit
  def edit; end

  # PATCH/PUT /pre_codes/:id
  def update
    if @pre_code.update(pre_code_params)
      replace_tags(@pre_code, params[:tag_names]) # ★ タグ更新
      redirect_to @pre_code, notice: "PreCode を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /pre_codes/:id
  def destroy
    @pre_code.destroy
    redirect_to pre_codes_path, notice: "PreCode を削除しました"
  end

  private

  # 所有者スコープで取得（他人IDは 404）
  def set_pre_code
    @pre_code = current_user.pre_codes.find(params[:id])
  end

  # Strong Parameters
  def pre_code_params
    attrs = params.require(:pre_code).permit(
      :title, :description, :body,
      :hint, :answer, :answer_code
    )

    # テキストだけサニタイズ（コードはサニタイズしない）
    sanitizer = if respond_to?(:sanitize_content, true)
                  method(:sanitize_content)
    else
                  ->(html) {
                    ActionController::Base.helpers.sanitize(
                      html,
                      tags: %w[b i em strong code pre br p ul ol li a],
                      attributes: %w[href]
                    )
                  }
    end

    # キーがある時だけ代入（nil を上書きしない）
    if attrs.key?(:hint)
      attrs[:hint] = sanitizer.call(attrs[:hint])
    end
    if attrs.key?(:answer)
      attrs[:answer] = sanitizer.call(attrs[:answer])
    end

    attrs
  end

  # === タグ関連 ===

  # "ruby,array" / ["ruby","array"] を配列に整形
  def parse_tags(val)
    Array(val).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
  end

  # Tag.normalize があれば使用。無ければ簡易正規化（NFKC→strip→downcase→空白正規化）
  def normalize_tag(name)
    if Tag.respond_to?(:normalize)
      Tag.normalize(name)
    else
      name.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " ")
    end
  end

  # タグ集合置換
  def replace_tags(pre_code, raw_names)
    return if raw_names.nil? # 未指定なら現集合を維持

    names = raw_names
              .to_s
              .tr("　", " ")               # 全角スペース→半角
              .split(/[,\s]+/)             # カンマ or 空白区切り
              .map(&:strip)
              .reject(&:blank?)
              .uniq

    new_tags = names.map { |n| Tag.find_or_create_by!(name: n) }
    pre_code.tags = new_tags
  end
end
