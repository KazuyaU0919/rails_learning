require "rails_helper"

RSpec.describe "Admin::BookSections", type: :request do
  describe "GET /admin/book_sections" do
    it "200 OK" do
      get "/admin/book_sections"
      expect(response).to have_http_status(:ok)
    end
  end
end
