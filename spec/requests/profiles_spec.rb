# spec/requests/profiles_spec.rb
require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user, password: "secret123", password_confirmation: "secret123") }

  before { sign_in user }

  describe "GET /profile" do
    it "表示できる" do
      get profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
    end
  end

  describe "GET /profile/edit" do
    it { get edit_profile_path; expect(response).to have_http_status(:ok) }
  end

  describe "PATCH /profile (プロフィール更新)" do
    it "名前を更新できる" do
      patch profile_path, params: { user: { name: "New Name" }, commit: "プロフィール更新" }
      expect(response).to redirect_to(profile_path)
      expect(user.reload.name).to eq("New Name")
    end
  end

  describe "PATCH /profile (パスワード更新)" do
    it "現在PWが一致すれば更新できる" do
      patch profile_path, params: {
        user: { current_password: "secret123", password: "newpass1", password_confirmation: "newpass1" },
        commit: "パスワード更新"
      }
      expect(response).to redirect_to(profile_path)
    end

    it "現在PWが違うと422" do
      patch profile_path, params: {
        user: { current_password: "wrong", password: "newpass1", password_confirmation: "newpass1" },
        commit: "パスワード更新"
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("現在のパスワードが違います")
    end

    # ===== Remember 強制失効の確認（追加） =====
    it "パスワード更新時に全端末のRememberが失効する" do
      user.remember! # digestが入る
      expect(user.remember_digest).to be_present

      patch profile_path, params: {
        user: { current_password: "secret123", password: "newpass1", password_confirmation: "newpass1" },
        commit: "パスワード更新"
      }
      expect(response).to redirect_to(profile_path)
      expect(user.reload.remember_digest).to be_blank
    end
  end

  # ===== 「他の端末からもログアウト」ボタンの確認（追加） =====
  describe "POST /profile/revoke_remember" do
    it "全端末のRememberが失効する" do
      user.remember!
      post revoke_remember_profile_path
      expect(response).to redirect_to(profile_path)
      expect(user.reload.remember_digest).to be_blank
    end
  end
end
