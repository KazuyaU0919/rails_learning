# app/controllers/book_sections_controller.rb
class BookSectionsController < ApplicationController
  include EditPermission
  before_action :set_book
  before_action :set_section, only: %i[show edit update]
  helper_method :logged_in?

  def show
    unless @section.is_free || logged_in?
      store_location(book_section_path(@book, @section)) if respond_to?(:store_location, true)
      redirect_to new_session_path, alert: "このページを表示するにはログインが必要です"
      return
    end
    @prev = @section.previous
    @next = @section.next
  end

  def edit
    nil unless require_edit_permission!(@section)
  end

  def update
    return unless require_edit_permission!(@section)

    attrs = section_params.slice(*@section.editable_attributes)
    attrs[:content] = RichTextSanitizer.call(attrs[:content])
    attrs[:lock_version] = section_params[:lock_version]

    begin
      @section.with_lock do
        @section.assign_attributes(attrs)
        if @section.save
          attach_images_from_content!(@section, prune: true)
          redirect_to book_section_path(@book, @section), notice: "更新しました"
        else
          render :edit, status: :unprocessable_entity
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash.now[:alert] = "他の編集と競合しました。最新の内容を確認して再度保存してください。"
      render :edit, status: :conflict
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def set_section
    @section = @book.book_sections.find(params[:id])
  end

  def section_params
    params.require(:book_section).permit(:content, :lock_version)
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
      keep = blobs.map(&:id)
      section.images.attachments.reject { |att| keep.include?(att.blob_id) }.each(&:purge)
    end
  end

  def logged_in?
    !!current_user
  end
end
