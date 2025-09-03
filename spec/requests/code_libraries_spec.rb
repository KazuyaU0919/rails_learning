# spec/requests/code_libraries_spec.rb
require "rails_helper"

RSpec.describe "CodeLibraries", type: :request do
  let(:me)    { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:other) { create(:user, password: "secret123", password_confirmation: "secret123") }

  # 基本データ
  let!(:mine)   { create(:pre_code, user: me,    title: "my code", description: "mine") }
  let!(:other_a) { create(:pre_code, user: other, title: "alpha",   description: "foo bar") }
  let!(:other_b) { create(:pre_code, user: other, title: "bravo",   description: "baz buzz") }

  describe "GET /code_libraries (index)" do
    it "ゲストでも200が返り、一覧が表示される" do
      get code_libraries_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(other_a.title, other_b.title)
    end

    it "ログイン時は自分の投稿が除外される" do
      sign_in(me)
      get code_libraries_path
      expect(response.body).to include(other_a.title)
      expect(response.body).not_to include(mine.title)
    end

    it "キーワード検索が効く（title/description の部分一致）" do
      # Ransack 形式のパラメータに合わせる
      get code_libraries_path, params: { q: { title_or_description_cont: "foo" } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(other_a.title)   # "foo" を含む説明
      expect(response.body).not_to include(other_b.title)
    end

    it "人気順（like_count）と利用数順（use_count）で並び替えできる" do
      users = create_list(:user, 5, password: "secret123", password_confirmation: "secret123")

      # いいね: other_b を3、other_a を1
      users.first(3).each { |u| create(:like, user: u, pre_code: other_b) }
      create(:like, user: users[3], pre_code: other_a)

      # 利用: other_a を2、other_b を1
      create(:used_code, user: users[0], pre_code: other_a)
      create(:used_code, user: users[1], pre_code: other_a)
      create(:used_code, user: users[2], pre_code: other_b)

      # デフォルト/人気順 → other_b が先頭
      get code_libraries_path, params: { sort: "popular" }
      expect(response.body.index(other_b.title)).to be < response.body.index(other_a.title)

      # 利用数順 → other_a が先頭
      get code_libraries_path, params: { sort: "used" }
      expect(response.body.index(other_a.title)).to be < response.body.index(other_b.title)

      # 新着順（念のため） → より新しい方が先頭
      newest = create(:pre_code, user: other, title: "newbie", created_at: 1.minute.from_now)
      get code_libraries_path, params: { sort: "newest" }
      expect(response.body.index("newbie")).to be < response.body.index(other_a.title)
    end

    it "ページネーションのリンク（rel=\"next\" or rel=\"prev\"）が出る（多件時）" do
      # Kaminari デフォルト 25 件想定 → 26 件で2ページ目が発生
      create_list(:pre_code, 26, user: other)
      get code_libraries_path
      expect(response.body).to include('rel="next"').or include('rel="prev"')
    end
  end

  describe "GET /code_libraries/:id (show)" do
    it "他人の投稿は200で表示できる" do
      get code_library_path(other_a)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(other_a.title)
    end

    it "自分の投稿へは /pre_codes へリダイレクトされる" do
      sign_in(me)
      get code_library_path(mine)
      expect(response).to redirect_to(pre_codes_path)
    end
  end
end
