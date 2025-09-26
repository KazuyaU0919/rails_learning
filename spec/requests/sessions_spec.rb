# spec/requests/sessions_spec.rb
require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "a@example.com", password: "secret123", password_confirmation: "secret123") }

  describe "GET /session/new" do
    it "200が返る" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    it "正しいメール/パスでログイン" do
      post session_path, params: { email: "a@example.com", password: "secret123" }
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(root_path)
    end

    it "誤った認証は422" do
      post session_path, params: { email: "a@example.com", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:user_id]).to be_blank
    end

    it "ログイン成功時に last_login_at が更新される" do
      expect(user.last_login_at).to be_nil

      post session_path, params: { email: "a@example.com", password: "secret123" }

      expect(response).to redirect_to(root_path)
      expect(user.reload.last_login_at).to be_present
    end

    context "BAN中ユーザーの場合" do
      let!(:banned) do
        # 既存Factoryに :banned trait を追加済みなのでそれを利用
        create(:user, :banned, email: "b@example.com", password: "secret123", password_confirmation: "secret123")
      end

      it "403で拒否し、セッションはセットされない" do
        post session_path, params: { email: "b@example.com", password: "secret123" }
        expect(response).to have_http_status(:forbidden)
        expect(session[:user_id]).to be_blank
        # メッセージの確認（文言は実装に合わせて）
        expect(response.body).to include("凍結")
      end
    end
  end
end
