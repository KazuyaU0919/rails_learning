# spec/requests/bookmarks_spec.rb
require "rails_helper"

RSpec.describe "Bookmarks", type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }
  let(:pc) { create(:pre_code, user: other) }

  before { sign_in user }

  it "作成できる" do
    expect {
      post bookmarks_path, params: { pre_code_id: pc.id }
    }.to change(Bookmark, :count).by(1)
  end

  it "削除できる" do
    b = create(:bookmark, user:, pre_code: pc)
    expect {
      delete bookmark_path(b)
    }.to change(Bookmark, :count).by(-1)
  end

  it "自分のPreCodeはブクマ不可（403）" do
    mine = create(:pre_code, user:)
    post bookmarks_path, params: { pre_code_id: mine.id }
    expect(response).to have_http_status(:forbidden)
  end

  it "上限300件を超えるとフラッシュで拒否" do
    create_list(:bookmark, 300, user:)
    post bookmarks_path, params: { pre_code_id: pc.id }
    expect(flash[:alert]).to include("300件以上")
  end

  it "一覧で only_bookmarked=1 を付けると自分のブクマだけに絞られる" do
    bookmarked = create(:pre_code, user: other)
    create(:bookmark, user:, pre_code: bookmarked)
    get code_libraries_path, params: { only_bookmarked: 1 }
    expect(response.body).to include(bookmarked.title)
  end
end
