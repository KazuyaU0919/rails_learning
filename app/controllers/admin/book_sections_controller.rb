class Admin::BookSectionsController < Admin::BaseController
  include ActionView::Helpers::SanitizeHelper
  layout "admin"

  def index
    @sections = BookSection.includes(:book).order(updated_at: :desc).page(params[:page])
  end

  def new
    @section = BookSection.new
  end

  def create
    @section = BookSection.new(section_params)
    @section.content = sanitize_content(@section.content)
    if @section.save
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
    attrs[:content] = sanitize_content(attrs[:content])
    if @section.update(attrs)
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
    params.require(:book_section).permit(:book_id, :heading, :content, :position, :is_free, images: [])
  end

  # 表示側で html_safe にしない運用でも一旦安全
  def sanitize_content(html)
    sanitize(html,
      tags: %w[p h1 h2 h3 h4 h5 h6 b i u strong em a ul ol li pre code blockquote br span div img],
      attributes: %w[href class target rel src alt]
    )
  end
end
