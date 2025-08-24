# spec/requests/admin/book_sections_spec.rb
require "rails_helper"

RSpec.describe "Admin::BookSections", type: :request do
  let(:admin) { create(:user, admin: true) }
  let(:book)  { create(:book) }

  before { sign_in_as(admin) }

  it "GET /admin/book_sections works" do
    get admin_book_sections_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sections")
  end

  it "POST creates with sanitized content" do
    html = %(<p>hello</p><script>alert(1)</script>)
    post admin_book_sections_path, params: {
      book_section: { book_id: book.id, heading: "H", position: 1, content: html }
    }
    follow_redirect!
    expect(response.body).to include("作成しました")
    expect(BookSection.last.content).to include("<p>hello</p>")
    expect(BookSection.last.content).not_to include("<script")
  end

  it "PATCH updates with sanitized content" do
    s = create(:book_section, book:, heading: "H", position: 1, content: "<p>ok</p>")
    dirty = %(<img src=x onerror='alert(1)'>good)

    patch admin_book_section_path(s), params: { book_section: { content: dirty } }

    s.reload
    expect(s.content).to include("good")
    expect(s.content).not_to include("onerror")
    expect(s.content).not_to include("alert(")
  end

  # content 内の signed_id <img> を自動 attach できること
  it "attaches blobs referenced in content to section.images" do
    # 1x1 PNG を作って ActiveStorage に直接アップロード（DirectUpload 相当）
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )

    # <img src="/rails/active_storage/blobs/redirect/:signed_id/:filename">
    img_src = rails_blob_path(blob, only_path: true) # redirect 付きの /rails/... を返す
    html    = %(<p>img</p><img src="#{img_src}">)

    post admin_book_sections_path, params: {
      book_section: { book_id: book.id, heading: "H", position: 1, content: html }
    }

    section = BookSection.last
    expect(section.images).to be_attached
    expect(section.images.first.blob_id).to eq(blob.id)
  end

  # 画像添付 → 一般ユーザー向け詳細ページに <img> が出ること
  it "attaches images and shows them on public show page" do
    post admin_book_sections_path, params: {
      book_section: {
        book_id:  book.id,
        heading:  "H",
        position: 1,
        content:  "<p>img</p>",
        images:   [ uploaded_image("sample.png") ] # spec/fixtures/files/sample.png
      }
    }

    section = BookSection.last
    expect(section.images).to be_attached

    get book_section_path(book, section)
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(%r{<img[^>]+src="(?:https?://[^"]+)?/rails/active_storage/[^"]+"})
  end
end
