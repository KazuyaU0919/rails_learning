# spec/requests/searches_spec.rb
require "rails_helper"

RSpec.describe "Searches", type: :request do
  let!(:pc1) { create(:pre_code, title: "配列操作", description: "配列の基礎", like_count: 3, use_count: 1) }
  let!(:pc2) { create(:pre_code, title: "文字列操作", description: "文字列の基礎", like_count: 5, use_count: 2) }

  it "q が空なら items は空" do
    get "/search/suggest", params: { q: "" }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["items"]).to eq([])
  end

  it "前方一致で最大8件返す" do
    get "/search/suggest", params: { q: "配" }
    expect(response).to have_http_status(:ok)
    items = JSON.parse(response.body)["items"]
    expect(items).to be_present
    expect(items.all? { |i| %w[title desc].include?(i["type"]) }).to be true
    expect(items.size).to be <= 8
  end
end
