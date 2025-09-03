# spec/requests/admin/authorization_smoke_spec.rb
require "rails_helper"

RSpec.describe "Admin Authorization", type: :request do
  # ← ここを「必ずパスワード付きの通常ユーザー」を作るように
  let(:user)  { create(:user, admin: false, password: "secret123", password_confirmation: "secret123") }
  # ← ここも同様に、admin だけ true にしたユーザー
  let(:admin) { create(:user, admin: true,  password: "secret123", password_confirmation: "secret123") }

  it "非adminは /admin に入れない" do
    sign_in_as(user)            # ヘルパが email/password で POST する想定
    get admin_root_path
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("管理者のみアクセス可能です")
  end

  it "adminは /admin に入れる" do
    sign_in_as(admin, password: "secret123")
    get admin_root_path
    expect(response).to have_http_status(:ok)
  end
end
