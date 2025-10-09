# app/controllers/admin/book_sections_controller.rb
# 管理: 書籍セクション
# - 保存前に content を許可リストで sanitize
# - 保存後は本文から ActiveStorage の signed_id を拾って attach/prune
class Admin::BookSectionsController < Admin::BaseController
  layout "admin"

  def index
    @sections = BookSection.includes(:book).order(updated_at: :desc).page(params[:page])
  end

  def new
    @section = BookSection.new
  end

  def create
    @section = BookSection.new(section_params)
    @section.content = RichTextSanitizer.call(@section.content)

    if @section.save
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
    attrs[:content] = RichTextSanitizer.call(attrs[:content])

    if @section.update(attrs)
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

  def section_params
    params.require(:book_section)
          .permit(:book_id, :heading, :content, :position, :is_free, :quiz_section_id, images: [])
  end

  SIGNED_ID_IMG_SRC =
    %r{/rails/active_storage/(?:blobs|representations)(?:/redirect)?/([A-Za-z0-9_\-=]+)}.freeze

  def attach_images_from_content!(section, prune: false)
    return if section.content.blank?
    signed_ids = section.content.scan(SIGNED_ID_IMG_SRC).flatten.uniq
    return if signed_ids.empty?

    blobs = signed_ids.filter_map do |sid|
      begin
        ActiveStorage::Blob.find_signed(sid)
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
        nil
      end
    end

    current_blob_ids = section.images.attachments.map(&:blob_id)
    blobs.reject { |b| current_blob_ids.include?(b.id) }.each { |blob| section.images.attach(blob) }

    if prune
      keep_ids = blobs.map(&:id)
      section.images.attachments.reject { |att| keep_ids.include?(att.blob_id) }.each(&:purge)
    end
  end
end
