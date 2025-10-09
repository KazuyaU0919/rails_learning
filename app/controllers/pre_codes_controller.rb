# app/controllers/pre_codes_controller.rb
class PreCodesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: %i[show edit update destroy]

  def index
    base = current_user.pre_codes

    if params[:tags].present?
      tag_keys = parse_tags(params[:tags])
      norm_keys = tag_keys.map { |n| normalize_tag(n) }.uniq
      if norm_keys.any?
        tag_ids = Tag.where(name_norm: norm_keys).pluck(:id)
        base =
          if tag_ids.any?
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
    # ★ Bullet (N+1) 対策
    @pre_codes = @q.result.order(id: :desc).preload(:tags).page(params[:page])
  end

  def show; end

  def new
    @pre_code = current_user.pre_codes.build
  end

  def create
    @pre_code = current_user.pre_codes.build(pre_code_params)
    if @pre_code.save
      replace_tags(@pre_code, params[:tag_names])
      redirect_to @pre_code, notice: "PreCode を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @pre_code.update(pre_code_params)
      replace_tags(@pre_code, params[:tag_names])
      redirect_to @pre_code, notice: "PreCode を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pre_code.destroy
    redirect_to pre_codes_path, notice: "PreCode を削除しました"
  end

  private

  def set_pre_code
    @pre_code = current_user.pre_codes.find(params[:id])
  end

  # Strong Parameters
  def pre_code_params
    attrs = params.require(:pre_code).permit(
      :title, :description, :body,
      :hint, :answer, :answer_code,
      :quiz_mode
    )

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

    attrs[:hint]   = sanitizer.call(attrs[:hint])   if attrs.key?(:hint)
    attrs[:answer] = sanitizer.call(attrs[:answer]) if attrs.key?(:answer)

    attrs
  end

  # === タグ関連 ===
  def parse_tags(val)
    Array(val).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
  end

  def normalize_tag(name)
    if Tag.respond_to?(:normalize)
      Tag.normalize(name)
    else
      name.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " ")
    end
  end

  def replace_tags(pre_code, raw_names)
    return if raw_names.nil?

    names = raw_names.to_s.tr("　", " ")
              .split(/[,\s]+/).map(&:strip).reject(&:blank?).uniq

    new_tags = names.map { |n| Tag.find_or_create_by!(name: n) }
    pre_code.tags = new_tags
  end
end
