# spec/requests/admin/book_sections_spec.rb
require "rails_helper"

RSpec.describe "Admin::BookSections", type: :request do
  let(:admin) { create(:user, admin: true, password: "password") }

  it "GET /admin/book_sections は 200" do
    sign_in_as(admin)
    get admin_book_sections_path
    expect(response).to have_http_status(:ok)
  end
end
