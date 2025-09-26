# spec/requests/books_spec.rb
require "rails_helper"

RSpec.describe "Books", type: :request do
  include ActionView::Helpers::NumberHelper

  describe "GET /books" do
    it "200 OK & 並び順(position昇順)で並ぶ" do
      # position を逆順で作って、表示は昇順になることを検証
      b3 = create(:book, title: "Title C", position: 3)
      b1 = create(:book, title: "Title A", position: 1)
      b2 = create(:book, title: "Title B", position: 2)

      get books_path
      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML.parse(response.body)

      # 本の一覧UL配下の「本詳細へのリンク」テキストを順に拾う
      # （ビューで <a href="/books/:id">Title ...</a> を想定）
      titles = doc.css('ul li a[href^="/books/"]').map do |a|
        a.text.strip.split("\n").first  # 改行前の部分だけ取る
      end

      expect(titles).to eq([ "Title A", "Title B", "Title C" ])
    end
  end

  describe "GET /books/:id" do
    it "200 OK & 目次(position昇順)が並ぶ" do
      book = create(:book, title: "順序テスト")
      s3 = create(:book_section, book:, heading: "C", position: 3)
      s1 = create(:book_section, book:, heading: "A", position: 1)
      s2 = create(:book_section, book:, heading: "B", position: 2)

      get book_path(book)
      expect(response).to have_http_status(:ok)

      doc = Nokogiri::HTML.parse(response.body)

      # 画面仕様に合わせたセレクタ（※既存のテストと同じやり方を踏襲）
      toc_lis = doc.css('ul li').select { |li| li.at_css('span.text-slate-400') }

      # 「1. 2. 3.」の表示順（見出し番号用 span を取得して trim）
      positions = toc_lis.map { |li| li.at_css('span.text-slate-400')&.text&.strip }
      expect(positions).to eq(%w[1. 2. 3.])

      # 見出しテキスト（リンク側）
      headings = toc_lis.map { |li| li.at_css('a span.text-slate-900')&.text&.strip }.compact
      expect(headings).to eq(%w[A B C])

      # 各セクションへのリンクがあること
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
