# spec/requests/admin/pre_codes_spec.rb
require "rails_helper"

RSpec.describe "Admin::PreCodes", type: :request do
  let(:admin)   { create(:user, admin: true) }
  let(:user)    { create(:user, name: "太郎", email: "taro@example.com") }
  let!(:p1)     { create(:pre_code, user:, title: "FizzBuzz", description: "数値の説明", like_count: 3, use_count: 10, created_at: 2.days.ago) }
  let!(:p2)     { create(:pre_code, user:, title: "Alpha",   description: "alpha desc", like_count: 5, use_count: 5,  created_at: 1.day.ago) }

  before { sign_in admin }

  describe "GET /admin/pre_codes" do
    it "一覧が表示される" do
      get admin_pre_codes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FizzBuzz", "Alpha")
    end

    it "タイトルで検索できる（部分一致・小文字化）" do
      get admin_pre_codes_path, params: { title: "fizz" }
      expect(response.body).to include("FizzBuzz")
      expect(response.body).not_to include("Alpha")
    end

    it "ユーザー名/メールで検索できる" do
      get admin_pre_codes_path, params: { user: "taro@" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("FizzBuzz", "Alpha")
    end

    it "ソート: like desc" do
      get admin_pre_codes_path, params: { sort: "likes" }
      expect(response.body.index("Alpha")).to be < response.body.index("FizzBuzz")
    end
  end

  describe "GET /admin/pre_codes/:id" do
    it { get admin_pre_code_path(p1); expect(response).to have_http_status(:ok) }
  end

  describe "PATCH /admin/pre_codes/:id" do
    it "更新できる" do
      patch admin_pre_code_path(p1), params: { pre_code: { title: "NewTitle" } }
      expect(response).to redirect_to(admin_pre_code_path(p1))
      expect(p1.reload.title).to eq("NewTitle")
    end

    it "失敗時は422" do
      patch admin_pre_code_path(p1), params: { pre_code: { title: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/pre_codes/:id" do
    it "削除できる" do
      expect {
        delete admin_pre_code_path(p2)
      }.to change { PreCode.count }.by(-1)
      expect(response).to redirect_to(admin_pre_codes_path)
    end
  end
end
