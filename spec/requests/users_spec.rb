# spec/requests/users_spec.rb
require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /users/new" do
    it "200が返る" do
      get new_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users" do
    it "ユーザーを作成してログインする" do
      params = { user: { name: "Alice", email: "a@example.com",
                         password: "secret123", password_confirmation: "secret123" } }

      expect {
        post users_path, params: params
      }.to change(User, :count).by(1)

      expect(session[:user_id]).to be_present
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("登録しました").or include("ログインしました")
    end

    context "既に同じメール（通常登録）が存在する場合" do
      let!(:existing) { create(:user, email: "dup@example.com") }

      it "作成されず、ログイン画面にリダイレクトしてフラッシュを表示する" do
        params = { user: { name: "Bob", email: "dup@example.com",
                           password: "secret123", password_confirmation: "secret123" } }

        expect {
          post users_path, params: params
        }.not_to change(User, :count)

        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("既に登録済みです").or include("登録済み")
      end

      it "大文字小文字が違っても同一として扱われる" do
        params = { user: { name: "Bob", email: "DuP@Example.com",
                           password: "secret123", password_confirmation: "secret123" } }

        expect {
          post users_path, params: params
        }.not_to change(User, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "同じメールのOAuthユーザーが既にいる場合" do
      # ユーザー作成後に Authentication を紐付けて「外部連携ユーザー」を表現
      let!(:oauth_user) do
        user = create(:user, email: "google@example.com")
        create(:authentication, user: user, provider: "google_oauth2", uid: "X1")
        user
      end

      it "（現在の仕様）通常登録は失敗し、ログイン画面に誘導される" do
        params = { user: { name: "Bob", email: "google@example.com",
                           password: "secret123", password_confirmation: "secret123" } }

        expect {
          post users_path, params: params
        }.not_to change(User, :count)   # ← ここを not_to に修正

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
