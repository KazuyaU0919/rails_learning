require "rails_helper"

RSpec.describe "Admin::Books", type: :request do
  describe "GET /admin/books" do
    it "200 OK" do
      get "/admin/books"
      expect(response).to have_http_status(:ok)
    end
  end
end
