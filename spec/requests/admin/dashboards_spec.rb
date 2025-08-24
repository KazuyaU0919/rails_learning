# spec/requests/admin/dashboards_spec.rb
require "rails_helper"

RSpec.describe "Admin::Dashboards", type: :request do
  let(:admin) { create(:user, admin: true, password: "password") }

  it "GET /admin は 200" do
    sign_in_as(admin)
    get admin_root_path
    expect(response).to have_http_status(:ok)
  end
end
