require "rails_helper"

RSpec.describe "Admin::Sessions", type: :request do
  describe "GET /admin/session/new" do
    it "200 OK" do
      get "/admin/session/new"
      expect(response).to have_http_status(:ok)
    end
  end
end
