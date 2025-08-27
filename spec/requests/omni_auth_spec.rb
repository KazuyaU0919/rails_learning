# spec/requests/omniauth_spec.rb
require "rails_helper"

RSpec.describe "OmniAuth", type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
    Rails.application.env_config.delete("omniauth.auth")
  end

  describe "GET /auth/:provider" do
    it "テストモードでは callback へ302でリダイレクトする" do
      mock_omniauth(provider: "github", uid: "gh-1", name: "GH User", email: "gh@example.com")
      get auth_path(provider: "github")
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(omni_auth_callback_path(provider: "github"))
    end
  end

  describe "GET /auth/:provider/callback" do
    context "既存の認証レコードがある" do
      let!(:auth) { create(:authentication, provider: "google_oauth2", uid: "U-1") }
      it "ユーザー/認証を増やさず root へ" do
        mock_omniauth(provider: "google_oauth2", uid: "U-1", email: auth.user.email)
        expect {
          get omni_auth_callback_path(provider: "google_oauth2")
        }.to change(User, :count).by(0).and change(Authentication, :count).by(0)
        expect(response).to redirect_to(root_path)
      end
    end

    context "2) 認証レコード無し + 同じメールの既存ユーザーがいる場合（紐付け）" do
      let(:provider) { "google_oauth2" }
      let!(:user)    { create(:user, email: "foo@example.com") }

      it "ユーザーは増えず、authが1件作成され、rootへリダイレクト" do
        mock_omniauth(provider:, uid: "NEW-UID", name: "G User", email: "foo@example.com")

        expect {
          get omni_auth_callback_path(provider:)
        }.to change(User, :count).by(0).and change(Authentication, :count).by(1)

        a = Authentication.last
        expect(a.user_id).to eq(user.id)
        expect(a.provider).to eq(provider)
        expect(a.uid).to eq("NEW-UID")

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:notice]).to satisfy { |m| m&.include?("連携しました") || m&.include?("ログインしました") }
      end
    end

    context "3) 認証レコードも該当ユーザーもない場合（新規作成）" do
      let(:provider) { "google_oauth2" }

      it "ユーザー1件 + auth1件が作成され、rootへリダイレクト" do
        mock_omniauth(provider:, uid: "BRAND-NEW", name: "G New", email: "new@example.com")

        expect {
          get omni_auth_callback_path(provider:)
        }.to change(User, :count).by(1).and change(Authentication, :count).by(1)

        user = User.order(:id).last
        auth = Authentication.last
        expect(auth.user_id).to eq(user.id)
        expect(auth.provider).to eq(provider)
        expect(auth.uid).to eq("BRAND-NEW")
        expect(user.email).to eq("new@example.com")

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:notice]).to satisfy { |m| m&.include?("新規登録しました") || m&.include?("ログインしました") }
      end
    end

    context "4) GitHub でも同様に動く（メール一致で既存ユーザーに紐付く）" do
      let(:provider) { "github" }

      it do
        user = create(:user, email: "octo@example.com")
        mock_omniauth(provider:, uid: "GH-1", name: "Octo", email: "octo@example.com")

        expect {
          get omni_auth_callback_path(provider:)
        }.to change(User, :count).by(0).and change(Authentication, :count).by(1)

        expect(Authentication.last.provider).to eq("github")
        expect(Authentication.last.user_id).to eq(user.id)
      end
    end

    context "5) 既存コードの回帰: 初回作成→2回目は作成せずログインのみ" do
      it do
        # 1回目：新規作成
        mock_omniauth(provider: "github", uid: "gh-1", name: "GH User", email: "gh@example.com")
        get omni_auth_callback_path(provider: "github")
        expect(response).to redirect_to(root_path)

        # 2回目：同じ認証情報 → Userは増えない
        mock_omniauth(provider: "github", uid: "gh-1", name: "GH User", email: "gh@example.com")
        expect {
          get omni_auth_callback_path(provider: "github")
        }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /auth/failure" do
    it "ログイン画面へリダイレクトする" do
      get omni_auth_failure_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
