# spec/requests/book_sections_spec.rb
require "rails_helper"

RSpec.describe "BookSections", type: :request do
  describe "GET /books/:book_id/sections/:id" do
    it "200 OK & 見出し/本文が見える & 前後ナビのリンクがある" do
      book = create(:book, title: "ナビテスト")
      s1 = create(:book_section, book:, heading: "第1章", content: "<p>one</p>", position: 1)
      s2 = create(:book_section, book:, heading: "第2章", content: "<p>two</p>", position: 2)
      s3 = create(:book_section, book:, heading: "第3章", content: "<p>three</p>", position: 3)

      get book_section_path(book, s2)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("第2章")
      expect(response.body).to include("two")  # HTML最小実装でも本文の一部が見えるはず

      # 前後リンク（存在する場合のみ）をURLで確認
      expect(response.body).to include(book_section_path(book, s1))
      expect(response.body).to include(book_section_path(book, s3))
    end

    it "先頭ページには前リンクが無い/末尾には次リンクが無い（ざっくり）" do
      book = create(:book)
      first = create(:book_section, book:, position: 1)
      last  = create(:book_section, book:, position: 2)

      # 先頭ページ
      get book_section_path(book, first)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("前へ")
      expect(response.body).to include(book_section_path(book, last))

      # 末尾ページ
      get book_section_path(book, last)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(book_section_path(book, first))
      expect(last.next).to be_nil
      expect(response.body).not_to include("次へ")
    end

    it "別のbookのセクションIDを指定すると404（ネストで保護されている）" do
      book_a = create(:book)
      book_b = create(:book)
      foreign_section = create(:book_section, book: book_b)

      get book_section_path(book_a, foreign_section)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("404")
    end

    it "存在しないIDなら404" do
      book = create(:book)
      get book_section_path(book, 9_999_999)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("404")
    end
  end
end
