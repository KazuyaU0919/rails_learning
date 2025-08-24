# spec/requests/admin/books_spec.rb
require "rails_helper"

RSpec.describe "Admin::Books", type: :request do
  let(:admin) { create(:user, admin: true, password: "password") }

  it "GET /admin/books は 200" do
    sign_in_as(admin)
    get admin_books_path
    expect(response).to have_http_status(:ok)
  end
end
