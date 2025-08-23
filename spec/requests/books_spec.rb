# spec/requests/books_spec.rb
require "rails_helper"

RSpec.describe "Books", type: :request do
  describe "GET /books" do
    it "200 OK & 各教本のタイトル/説明/セクション数が見える" do
      book = create(:book, title: "Rails Book", description: "Rails入門")
      create_list(:book_section, 3, book:)

      get books_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rails Book")
      expect(response.body).to include("Rails入門")
      # index ビューの文言「全 X セクション」に合わせる
      expect(response.body).to include("全 3 セクション")
    end
  end

  describe "GET /books/:id" do
    it "200 OK & 目次（position昇順）が並ぶ" do
      book = create(:book, title: "順序テスト")
      # position: 1,2,3 の並びで出ることを確認（本文は最小限）
      s3 = create(:book_section, book:, heading: "C", position: 3)
      s1 = create(:book_section, book:, heading: "A", position: 1)
      s2 = create(:book_section, book:, heading: "B", position: 2)

      get book_path(book)
      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML.parse(response.body)

      # 位置（1., 2., 3.）の並びを検証
      positions = doc.css('ul li span.text-slate-400').map { |n| n.text.strip }
      expect(positions).to eq(%w[1. 2. 3.])

      # 見出し（A, B, C）の並びを検証
      headings = doc.css('ul li a').map(&:text)
      expect(headings).to eq(%w[A B C])

      # ついでにリンクが存在することも確認（あなたの既存アサートでもOK）
      expect(response.body).to include(book_section_path(book, s1))
      expect(response.body).to include(book_section_path(book, s2))
      expect(response.body).to include(book_section_path(book, s3))
    end

    it "存在しないIDなら404" do
      get book_path(9_999_999)
      expect(response).to have_http_status(:not_found)
      # ApplicationController の 404 ハンドラは public/404.html を返す想定
      expect(response.body).to include("404")
    end
  end
end
