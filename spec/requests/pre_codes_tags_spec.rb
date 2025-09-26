# spec/requests/pre_codes_tags_spec.rb
require "rails_helper"
RSpec.describe "PreCode tags", type: :request do
  let(:user) { create(:user) }

  describe "AND検索" do
    it "選択したタグすべてを含むものだけ返る" do
      sign_in user
      t1 = create(:tag, name: "ruby")
      t2 = create(:tag, name: "array")
      pc_ok  = create(:pre_code, user:)
      pc_ng1 = create(:pre_code, user:)
      pc_ng2 = create(:pre_code, user:)
      pc_ok.tags  << [ t1, t2 ]
      pc_ng1.tags << [ t1 ]
      pc_ng2.tags << [ t2 ]

      get pre_codes_path, params: { tags: "ruby,array" }
      expect(response.body).to include(pc_ok.title)
      expect(response.body).not_to include(pc_ng1.title)
      expect(response.body).not_to include(pc_ng2.title)
    end
  end

  describe "作成/更新" do
    before { sign_in user }

    it "作成時にタグ付与できる" do
      post pre_codes_path, params: { pre_code: attributes_for(:pre_code), tag_names: "ruby, array" }
      pc = PreCode.last
      expect(pc.tags.map(&:name_norm)).to match_array(%w[ruby array])
    end

    it "更新でタグ集合が置き換わる" do
      pc = create(:pre_code, user:)
      post pre_codes_path, params: { pre_code: attributes_for(:pre_code), tag_names: "a,b" } if pc.nil?
      patch pre_code_path(pc), params: { pre_code: { title: pc.title, body: pc.body }, tag_names: "x,y" }
      expect(pc.reload.tags.map(&:name_norm)).to match_array(%w[x y])
    end
  end
end
