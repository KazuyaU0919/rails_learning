# spec/requests/book_sections_spec.rb
require "rails_helper"

RSpec.describe "Admin::BookSections", type: :request do
  let(:admin) { create(:user, admin: true, password: "secret", password_confirmation: "secret") }
  let(:book)  { create(:book) }

  # 独自ログインヘルパで実際にセッションを張る
  before { sign_in_as(admin, password: "secret") }

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

  it "attaches blobs referenced in content to section.images" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )

    img_src = rails_blob_path(blob, only_path: true)
    html    = %(<p>img</p><img src="#{img_src}">)

    post admin_book_sections_path, params: {
      book_section: { book_id: book.id, heading: "H", position: 1, content: html }
    }

    section = BookSection.last
    expect(section.images).to be_attached
    expect(section.images.first.blob_id).to eq(blob.id)
  end

  it "shows inline <img> in public show page when content includes a blob URL" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )
    img_src = rails_blob_path(blob, only_path: true)
    html = %(<p>img</p><img src="#{img_src}">)

    post admin_book_sections_path, params: {
      book_section: { book_id: book.id, heading: "H", position: 1, content: html }
    }

    section = BookSection.last
    expect(section.images).to be_attached
    expect(section.images.first.blob_id).to eq(blob.id)

    get book_section_path(book, section)
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(%r{<img[^>]+src="(?:https?://[^"]+)?/rails/active_storage/[^"]+"})
  end
end
