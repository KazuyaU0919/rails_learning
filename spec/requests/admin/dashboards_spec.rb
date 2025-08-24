require "rails_helper"

RSpec.describe "Admin::Dashboards", type: :request do
  describe "GET /admin" do
    it "200 OK" do
      get "/admin"
      # 仮実装なので 200 さえ返ればよい
      expect(response).to have_http_status(:ok)
    end
  end
end
