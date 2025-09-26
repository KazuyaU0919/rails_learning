# spec/requests/omni_auth_spec.rb
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

      it "ログイン成功時に last_login_at が更新される" do
        mock_omniauth(provider: "google_oauth2", uid: "U-1", email: auth.user.email)

        get omni_auth_callback_path(provider: "google_oauth2")

        expect(response).to redirect_to(root_path)
        expect(auth.user.reload.last_login_at).to be_present
      end
    end

    context "既存ユーザーとメールが一致する場合は認証が紐付く" do
      let(:provider) { "google_oauth2" }
      let!(:user)    { create(:user, email: "foo@example.com") }

      it "ユーザーは増えず auth が1件作成される" do
        mock_omniauth(provider:, uid: "NEW-UID", name: "G User", email: "foo@example.com")
        expect {
          get omni_auth_callback_path(provider:)
        }.to change(Authentication, :count).by(1)
        expect(Authentication.last.user_id).to eq(user.id)
        expect(response).to redirect_to(root_path)
      end

      it "紐付け成功時に last_login_at が更新される" do
        mock_omniauth(provider: "google_oauth2", uid: "NEW-UID", email: user.email)

        get omni_auth_callback_path(provider: "google_oauth2")

        expect(response).to redirect_to(root_path)
        expect(user.reload.last_login_at).to be_present
      end
    end

    context "該当ユーザーも認証もない場合" do
      it "新規ユーザーと認証が作成される" do
        mock_omniauth(provider: "github", uid: "BRAND-NEW", name: "Newbie", email: "new@example.com")
        expect {
          get omni_auth_callback_path(provider: "github")
        }.to change(User, :count).by(1).and change(Authentication, :count).by(1)
        expect(response).to redirect_to(root_path)
      end
    end

    context "同じ認証で2回目ログインした場合" do
      it "Userは増えずログインだけされる" do
        mock_omniauth(provider: "github", uid: "gh-1", email: "gh@example.com")
        get omni_auth_callback_path(provider: "github")
        expect {
          get omni_auth_callback_path(provider: "github")
        }.not_to change(User, :count)
      end
    end

    # ===== Remember 発行の確認（追加） =====
    it "provider ログイン成功時に remember=1 でRememberクッキーが発行される" do
      user = create(:user, email: "foo@example.com")
      mock_omniauth(provider: "github", uid: "u1", email: "foo@example.com")

      get omni_auth_callback_path(provider: "github", remember: "1")

      expect(response).to redirect_to(root_path)
      expect(cookies['remember_me']).to be_present
    end
  end

  describe "GET /auth/failure" do
    it "ログイン画面へリダイレクトする" do
      get omni_auth_failure_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
