# spec/requests/used_codes_spec.rb
require "rails_helper"

RSpec.describe "UsedCodes", type: :request do
  let(:user)     { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:pre_code) { create(:pre_code) }

  describe "認可" do
    it "未ログインは作成にアクセスできずリダイレクト" do
      post used_codes_path, params: { pre_code_id: pre_code.id }
      expect(response).to have_http_status(:found)
    end
  end

  describe "ログイン後" do
    before { sign_in(user) }

    it "POST /used_codes で利用記録が1件作成され use_count が1増える" do
      expect {
        post used_codes_path, params: { pre_code_id: pre_code.id }
      }.to change(UsedCode, :count).by(1)
       .and change { pre_code.reload.use_count }.by(1)
      expect(response).to have_http_status(:ok).or have_http_status(:found)
    end

    it "同じユーザーは同じ PreCode を重複記録しない（find_or_create_by!）" do
      create(:used_code, user: user, pre_code: pre_code)
      expect {
        post used_codes_path, params: { pre_code_id: pre_code.id }
      }.not_to change(UsedCode, :count)
      expect(pre_code.reload.use_count).to eq(1)
    end
  end
end
