# spec/requests/likes_spec.rb
require "rails_helper"

RSpec.describe "Likes", type: :request do
  let(:user)   { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:author) { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:pre_code) { create(:pre_code, user: author) }

  describe "認可" do
    it "未ログインは作成にアクセスできずリダイレクト" do
      post likes_path, params: { pre_code_id: pre_code.id }
      expect(response).to have_http_status(:found)
    end
  end

  describe "ログイン後" do
    before { sign_in(user) }

    it "POST /likes で Like と like_count が1増える" do
      expect {
        post likes_path, params: { pre_code_id: pre_code.id }
      }.to change(Like, :count).by(1)
       .and change { pre_code.reload.like_count }.by(1)
      expect(response).to have_http_status(:ok).or have_http_status(:redirect)
    end

    it "同じユーザーは重複Likeできない" do
      create(:like, user:, pre_code:)
      expect {
        post likes_path, params: { pre_code_id: pre_code.id }
      }.not_to change(Like, :count)
      expect(pre_code.reload.like_count).to eq(1)
    end

    it "DELETE /likes/:id で自分の Like を削除できる" do
      like = user.likes.create!(pre_code:)
      expect {
        delete like_path(like)
      }.to change(Like, :count).by(-1)
       .and change { pre_code.reload.like_count }.by(-1)
      expect(response).to have_http_status(:ok).or have_http_status(:found)
    end

    it "自分の投稿にはいいねできず forbidden" do
      my_pre_code = create(:pre_code, user:)
      expect {
        post likes_path, params: { pre_code_id: my_pre_code.id }
      }.not_to change(Like, :count)
      expect(my_pre_code.reload.like_count).to eq(0)
      expect(response).to have_http_status(:forbidden)
    end

    it "他人の Like は削除できず 404" do
      other_like = create(:like, user: author, pre_code:)
      delete like_path(other_like)
      expect(response).to have_http_status(:not_found)
    end
  end
end
