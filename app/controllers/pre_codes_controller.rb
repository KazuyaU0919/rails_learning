# ============================================================
# PreCodesController
# ------------------------------------------------------------
# ユーザー自身の PreCode（初期データ）を管理する。
# - 一覧、詳細、作成、更新、削除を提供。
# - タグ付け機能あり。
# - ユーザー本人のみアクセス可。
# ------------------------------------------------------------
# 特徴：
#   - タグの正規化・付け替え処理（replace_tags）
#   - HTMLサニタイズによる安全性担保
#   - Bullet対策のpreload（N+1回避）
# ============================================================

class PreCodesController < ApplicationController
  before_action :require_login!
  before_action :set_pre_code, only: %i[show edit update destroy]

  # =======================
  # 一覧
  # =======================
  def index
    base = current_user.pre_codes

    # --- タグフィルタ（AND検索）---
    if params[:tags].present?
      tag_keys  = parse_tags(params[:tags])
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

    # --- 検索（ransack使用）---
    @q = base.ransack(params[:q])

    # --- N+1 対策 + 並び順 ---
    @pre_codes = @q.result.order(id: :desc).preload(:tags).page(params[:page])
  end

  # =======================
  # 詳細
  # =======================
  def show; end

  # =======================
  # 新規作成
  # =======================
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

  # =======================
  # 編集 / 更新
  # =======================
  def edit; end

  def update
    if @pre_code.update(pre_code_params)
      replace_tags(@pre_code, params[:tag_names])
      redirect_to @pre_code, notice: "PreCode を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # =======================
  # 削除
  # =======================
  def destroy
    @pre_code.destroy
    redirect_to pre_codes_path, notice: "PreCode を削除しました"
  end

  private

  # =======================
  # 共通セットアップ
  # =======================
  def set_pre_code
    @pre_code = current_user.pre_codes.find(params[:id])
  end

  # =======================
  # Strong Parameters
  # =======================
  def pre_code_params
    attrs = params.require(:pre_code).permit(
      :title, :description, :body,
      :hint, :answer, :answer_code, :quiz_mode
    )

    # --- HTMLサニタイズ ---
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

  # =======================
  # タグ関連ユーティリティ
  # =======================

  # 例："ruby,array" → ["ruby","array"]
  def parse_tags(val)
    Array(val).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
  end

  # Tag.normalize があればそちらを使用
  def normalize_tag(name)
    if Tag.respond_to?(:normalize)
      Tag.normalize(name)
    else
      name.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/\s+/, " ")
    end
  end

  # タグ付け替え（既存タグを全置換）
  def replace_tags(pre_code, raw_names)
    return if raw_names.nil?

    names = raw_names.to_s.tr("　", " ")
              .split(/[,\s]+/).map(&:strip).reject(&:blank?).uniq

    new_tags = names.map { |n| Tag.find_or_create_by!(name: n) }
    pre_code.tags = new_tags
  end
end
