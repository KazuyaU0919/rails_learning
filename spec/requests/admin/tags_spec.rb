# spec/requests/admin/tags_spec.rb
require "rails_helper"
RSpec.describe "Admin::Tags", type: :request do
  let(:admin) { create(:user, admin: true) }
  before { sign_in admin }

  it "統合できる" do
    from = create(:tag, name: "ruby")
    to   = create(:tag, name: "ruby-lang")
    pc = create(:pre_code, user: admin); pc.tags << from
    post merge_admin_tags_path, params: { from_id: from.id, to_id: to.id }
    expect(response).to redirect_to(admin_tags_path)
    expect(pc.reload.tags).to include(to)
  end

  it "未使用タグは削除できる" do
    t = create(:tag, name: "unused")
    expect { delete admin_tag_path(t) }.to change(Tag, :count).by(-1)
  end

  it "index に未使用タグも表示される" do
    sign_in admin
    create(:tag, name: "unused") # taggings_count: 0
    get admin_tags_path
    expect(response.body).to include("unused")
  end
end
