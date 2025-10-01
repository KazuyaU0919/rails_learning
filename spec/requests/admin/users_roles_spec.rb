# spec/requests/admin/users_roles_spec.rb
require "rails_helper"

RSpec.describe "Admin::Users badges", type: :request do
  let!(:admin_user) { create(:user, admin: true) }

  before { sign_in admin_user }

  it "admin / editor / sub_editor / 一般 のバッジが表示される" do
    u_admin  = create(:user, admin: true)
    u_editor = create(:user, editor: true)
    u_sub    = create(:user)
    create(:editor_permission, user: u_sub, target_type: "BookSection", target_id: 1, role: :sub_editor)
    u_gen    = create(:user)

    get admin_users_path
    expect(response).to have_http_status(:ok)

    # 文字列マッチ（ビュー側のバッジラベルに追随）
    expect(response.body).to include("管理者")     # admin
    expect(response.body).to include("編集者")     # editor
    expect(response.body).to include("sub_editor") # sub_editor
    expect(response.body).to include("一般")       # general
  end
end
