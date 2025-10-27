# app/controllers/admin/book_sections_controller.rb
# ============================================================
# 管理: 書籍セクション（BookSection）
# ------------------------------------------------------------
# ・一覧/作成/更新/削除の基本 CRUD
# ・保存前: content をホワイトリストで sanitize
# ・保存後: 本文中の ActiveStorage signed_id を元に画像を attach / prune
#   - 「prune: true」のとき、本文から参照が外れた画像を自動削除します
# ============================================================
class Admin::BookSectionsController < Admin::BaseController
  layout "admin"

  # =======================
  # アクション
  # =======================
  def index
    # N+1防止のため book を preload。更新降順で管理しやすく。
    @sections = BookSection.includes(:book).order(updated_at: :desc).page(params[:page])
  end

  def new
    @section = BookSection.new
  end

  def create
    @section = BookSection.new(section_params)
    # 保存前に HTML サニタイズ：危険なタグを排除
    @section.content = RichTextSanitizer.call(@section.content)

    if @section.save
      # 保存後に本文中の signed_id を解析して画像を attach
      attach_images_from_content!(@section)
      redirect_to admin_book_sections_path, notice: "作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @section = BookSection.find(params[:id])
  end

  def update
    @section = BookSection.find(params[:id])

    attrs = section_params
    # 更新時もサニタイズを徹底
    attrs[:content] = RichTextSanitizer.call(attrs[:content])

    if @section.update(attrs)
      # prune: true で、本文から外れた画像を自動削除（整合性の維持）
      attach_images_from_content!(@section, prune: true)
      redirect_to admin_book_sections_path, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    BookSection.find(params[:id]).destroy
    redirect_to admin_book_sections_path, notice: "削除しました"
  end

  private

  # =======================
  # Strong Parameters
  # =======================
  def section_params
    params.require(:book_section)
          .permit(:book_id, :heading, :content, :position, :is_free, :quiz_section_id, images: [])
  end

  # =======================
  # 本文 -> 画像アタッチ
  # -----------------------
  # Quill 等が生成する URL から ActiveStorage の signed_id を抽出
  # /rails/active_storage/blobs/redirect/:signed_id/:filename
  # /rails/active_storage/representations/... にも対応
  # =======================
  SIGNED_ID_IMG_SRC =
    %r{/rails/active_storage/(?:blobs|representations)(?:/redirect)?/([A-Za-z0-9_\-=]+)}.freeze

  def attach_images_from_content!(section, prune: false)
    return if section.content.blank?

    # 本文から signed_id をすべて抽出（重複除去）
    signed_ids = section.content.scan(SIGNED_ID_IMG_SRC).flatten.uniq
    return if signed_ids.empty?

    # 失効/不正 sid は rescue して除外
    blobs = signed_ids.filter_map do |sid|
      begin
        ActiveStorage::Blob.find_signed(sid)
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
        nil
      end
    end

    # 既存 attach と比較して新規分だけ attach
    current_blob_ids = section.images.attachments.map(&:blob_id)
    blobs.reject { |b| current_blob_ids.include?(b.id) }.each { |blob| section.images.attach(blob) }

    # prune 指定時は、本文から参照が外れた画像を purge
    if prune
      keep_ids = blobs.map(&:id)
      section.images.attachments.reject { |att| keep_ids.include?(att.blob_id) }.each(&:purge)
    end
  end
end
