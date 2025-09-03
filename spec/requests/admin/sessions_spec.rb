# spec/requests/admin/sessions_spec.rb
require "rails_helper"

RSpec.describe "Admin::Sessions", type: :request do
  let(:admin) { create(:user, admin: true,  password: "secret", password_confirmation: "secret") }
  let(:user)  { create(:user, admin: false, password: "secret", password_confirmation: "secret") }

  it "admin はログインできる" do
    post admin_session_path, params: { email: admin.email, password: "secret" }
    expect(response).to redirect_to(admin_root_path)
  end

  it "非admin は拒否される" do
    post admin_session_path, params: { email: user.email, password: "secret" }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "ログアウトできる" do
    post admin_session_path, params: { email: admin.email, password: "secret" }
    delete admin_session_path
    expect(response).to redirect_to(root_path)
  end
end
