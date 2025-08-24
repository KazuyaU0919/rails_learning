# spec/requests/admin/authorization_smoke_spec.rb
require "rails_helper"

RSpec.describe "Admin Authorization", type: :request do
  let(:user)  { create(:user, admin: false) }
  let(:admin) { create(:user, admin: true)  }

  it "非adminは /admin に入れない" do
    sign_in_as(user)
    get admin_root_path
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("管理者のみアクセス可能です")
  end

  it "adminは /admin に入れる" do
    sign_in_as(admin)
    get admin_root_path
    expect(response).to have_http_status(:ok)
  end
end
