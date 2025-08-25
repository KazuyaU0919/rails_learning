# app/controllers/admin/book_sections_controller.rb
# 管理: 書籍セクション
# - create/update 前に content を sanitize（既存）
# - 保存後: content 内の <img src="/rails/active_storage/.../:signed_id/..."> を拾って attach
# - update 時: いまの content に出てこない画像を prune（任意機能）
class Admin::BookSectionsController < Admin::BaseController
  include ActionView::Helpers::SanitizeHelper
  layout "admin"

  # 一覧
  def index
    @sections = BookSection.includes(:book).order(updated_at: :desc).page(params[:page])
  end

  # 新規
  def new
    @section = BookSection.new
  end

  # 作成
  def create
    @section = BookSection.new(section_params)

    # ① XSS 対策: 保存前に許可リストでサニタイズ
    @section.content = sanitize_content(@section.content)

    if @section.save
      # ② 本文に含まれる signed_id を抽出して ActiveStorage に attach
      attach_images_from_content!(@section)

      redirect_to admin_book_sections_path, notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 編集
  def edit
    @section = BookSection.find(params[:id])
  end

  # 更新
  def update
    @section = BookSection.find(params[:id])

    # Strong Params を受けてから content だけサニタイズして差し替え
    attrs = section_params
    attrs[:content] = sanitize_content(attrs[:content])

    if @section.update(attrs)
      # ③ update 後に再スキャンして attach。
      #    prune: true の時は、本文から消えた画像を purge（整理）する
      attach_images_from_content!(@section, prune: true)

      redirect_to admin_book_sections_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除
  def destroy
    BookSection.find(params[:id]).destroy
    redirect_to admin_book_sections_path, notice: "削除しました"
  end

  private

  # ==== Strong Params =========================================================
  def section_params
    # ActiveStorage 複数添付は images: [] で受ける（既存）
    params.require(:book_section).permit(:book_id, :heading, :content, :position, :is_free, images: [])
  end

  # ==== サニタイズ（保存前フィルタ）============================================
  # 表示側で html_safe にしない運用でも安全だが、二重防御として sanitize する
  def sanitize_content(html)
    sanitize(
      html,
      # 許可タグは用途に応じて調整。img を許可して DirectUpload の URL を通す
      tags: %w[p h1 h2 h3 h4 h5 h6 b i u strong em a ul ol li pre code blockquote br span div img],
      # href/src/class/rel/alt など最低限。必要なら loading / width / height 等を追加
      attributes: %w[href class target rel src alt]
    )
  end

  # ==== 本文から signed_id を拾って attach / prune =============================
  # /rails/active_storage/blobs/:signed_id/... あるいは
  # /rails/active_storage/blobs/redirect/:signed_id/... のどちらも拾う
  SIGNED_ID_IMG_SRC =
    %r{/rails/active_storage/(?:blobs|representations)(?:/redirect)?/([A-Za-z0-9_\-=]+)}.freeze

  # @param section [BookSection]
  # @param prune [Boolean] true のとき、本文に出てこない既存添付を purge する
  def attach_images_from_content!(section, prune: false)
    return if section.content.blank?

    # 1) 本文から signed_id を収集
    signed_ids = section.content.scan(SIGNED_ID_IMG_SRC).flatten.uniq
    return if signed_ids.empty?

    # 2) signed_id → Blob へ安全に解決（壊れたIDはスキップ）
    blobs = signed_ids.filter_map do |sid|
      begin
        ActiveStorage::Blob.find_signed(sid)
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
        nil
      end
    end

    # 3) 新規 attach（既に同一 blob が付いているものはスキップ）
    current_blob_ids = section.images.attachments.map(&:blob_id)
    blobs.reject { |b| current_blob_ids.include?(b.id) }.each do |blob|
      section.images.attach(blob)
    end

    # 4) prune: true の場合、本文に出ない画像を削除してクリーンアップ
    if prune
      keep_ids = blobs.map(&:id)
      section.images.attachments.reject { |att| keep_ids.include?(att.blob_id) }.each(&:purge)
    end
  end
end
