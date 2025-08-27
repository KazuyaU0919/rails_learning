# spec/requests/books_spec.rb
require "rails_helper"

RSpec.describe "Books", type: :request do
  include ActionView::Helpers::NumberHelper

  describe "GET /books" do
    it "200 OK & 各教本のタイトル/説明/セクション数(counter_cache) が見える" do
      book = create(:book, title: "Rails Book", description: "Rails入門")
      create_list(:book_section, 3, book:)
      book.reload

      get books_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rails Book")
      expect(response.body).to include("Rails入門")
      expect(response.body).to include(number_with_delimiter(book.book_sections_count))
    end
  end

  describe "GET /books/:id" do
    it "200 OK & 目次(position昇順) が並ぶ" do
      book = create(:book, title: "順序テスト")
      s3 = create(:book_section, book:, heading: "C", position: 3)
      s1 = create(:book_section, book:, heading: "A", position: 1)
      s2 = create(:book_section, book:, heading: "B", position: 2)

      get book_path(book)
      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML.parse(response.body)

      # 目次の <li> を「番号用の span があるもの」に限定
      toc_lis = doc.css('ul li').select { |li| li.at_css('span.text-slate-400') }

      # 位置 (1., 2., 3.) の並び
      positions = toc_lis.map { |li| li.at_css('span.text-slate-400').text.strip }
      expect(positions).to eq(%w[1. 2. 3.])

      # 見出し (A, B, C) の並び
      # 行全体リンク化後は、見出しテキストは span.text-slate-900 に入る
      headings = toc_lis.map { |li| li.at_css('a span.text-slate-900')&.text&.strip }.compact
      expect(headings).to eq(%w[A B C])

      # リンクが存在することの確認
      expect(response.body).to include(book_section_path(book, s1))
      expect(response.body).to include(book_section_path(book, s2))
      expect(response.body).to include(book_section_path(book, s3))
    end

    it "存在しないIDなら404" do
      get book_path(9_999_999)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("404")
    end
  end
end
