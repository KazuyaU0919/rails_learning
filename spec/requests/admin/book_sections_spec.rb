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
    # 先にレコードを作成（健全な内容）
    s = create(:book_section, book:, heading: "H", position: 1, content: "<p>ok</p>")

    # 悪意ある属性（onerror など）を含む HTML を更新として送る
    dirty = %(<img src=x onerror='alert(1)'>good)

    patch admin_book_section_path(s), params: {
      book_section: { content: dirty }
    }

    s.reload
    expect(s.content).to include("good")         # 中身は残る
    expect(s.content).not_to include("onerror")  # 危険な属性は除去される
    expect(s.content).not_to include("alert(")   # スクリプト片もない
  end

  # 画像添付 → 一般ユーザー向け詳細ページに <img> が出ること
  it "attaches images and shows them on public show page" do
    # 画像を1枚添付して作成
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

    # 一般側の詳細ページで表示されるか
    get book_section_path(book, section)
    expect(response).to have_http_status(:ok)

    # ActiveStorage の画像URL（blob/representations どちらでも）をざっくり検出
    # 相対 (/rails/...) でも絶対 (http[s]://xxx/rails/...) でも OK
    expect(response.body).to match(
      %r{<img[^>]+src="(?:https?://[^"]+)?/rails/active_storage/[^"]+"}
    )
  end
end
