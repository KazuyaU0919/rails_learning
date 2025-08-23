# spec/requests/books_spec.rb
require "rails_helper"

RSpec.describe "Books", type: :request do
  describe "GET /books" do
    it "200 OK & 教本タイトル/説明が見える" do
      book = create(:book, title: "Rails Book", description: "Rails入門")
      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rails Book")
      expect(response.body).to include("Rails入門")
    end
  end

  describe "GET /books/:id" do
    it "200 OK & 目次（position昇順）が並ぶ" do
      book = create(:book, title: "順序テスト")
      s3 = create(:book_section, book:, heading: "C", position: 3)
      s1 = create(:book_section, book:, heading: "A", position: 1)
      s2 = create(:book_section, book:, heading: "B", position: 2)

      get book_path(book)
      expect(response).to have_http_status(:ok)

      # 画面上の出現順を index でざっくり検証
      body = response.body
      i1 = body.index("A")
      i2 = body.index("B")
      i3 = body.index("C")
      expect(i1).to be < i2
      expect(response.body).to match(/>A<\/a>.*>B<\/a>.*>C<\/a>/m)
    end

    it "存在しないIDなら404" do
      get book_path(9_999_999)
      expect(response).to have_http_status(:not_found)
      # ApplicationController の 404 ハンドラが HTML を返す想定
      expect(response.body).to include("404")
    end
  end
end
