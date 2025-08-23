# spec/requests/book_sections_spec.rb
require "rails_helper"

RSpec.describe "BookSections", type: :request do
  describe "GET /books/:book_id/sections/:id" do
    it "200 OK & 見出し/本文が見える & 前後セクションのリンクがある" do
      book = create(:book, title: "ナビテスト")
      s1 = create(:book_section, book:, heading: "第1章", content: "<p>one</p>",  position: 1)
      s2 = create(:book_section, book:, heading: "第2章", content: "<p>two</p>",  position: 2)
      s3 = create(:book_section, book:, heading: "第3章", content: "<p>three</p>", position: 3)

      # 中間（s2）を表示
      get book_section_path(book, s2)
      expect(response).to have_http_status(:ok)

      expect(response.body).to include("第2章")
      expect(response.body).to include("two") # 本文の一部が見えるはず

      # 前後リンク（URL が本文に含まれるかを確認）
      expect(response.body).to include(book_section_path(book, s1))
      expect(response.body).to include(book_section_path(book, s3))
    end

    it "先頭ページには『前へ』が無く、末尾には『次へ』が無い" do
      book  = create(:book)
      first = create(:book_section, book:, position: 1)
      last  = create(:book_section, book:, position: 2)

      # 先頭ページ
      get book_section_path(book, first)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("前へ") # 文言ベース
      expect(response.body).to include(book_section_path(book, last)) # 次リンクはある

      # 末尾ページ
      get book_section_path(book, last)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(book_section_path(book, first)) # 前リンクはある
      expect(response.body).not_to include("次へ") # 次リンクは無い
    end

    it "FREE バッジ（is_free: true のセクション）を教本トップで表示できる" do
      book = create(:book)
      create(:book_section, book:, is_free: true,  position: 1, heading: "Free")
      create(:book_section, book:, is_free: false, position: 2, heading: "Paid")

      get book_path(book)
      expect(response).to have_http_status(:ok)
      # books/show.html.erb の FREE バッジ（クラス/文言のどちらかで緩くチェック）
      expect(response.body).to include("FREE")
    end

    it "別の book のセクションIDを指定すると 404（ネストで保護されている）" do
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
