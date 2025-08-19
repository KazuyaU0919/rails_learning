# spec/requests/omni_auth_spec.rb
require 'rails_helper'

RSpec.describe 'OmniAuth', type: :request do
  describe 'GET /auth/:provider' do
    it 'テストモードでは callback へ302でリダイレクトする' do
      get auth_path(provider: 'github')
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(omni_auth_callback_path(provider: 'github'))
    end
  end

  describe 'GET /auth/:provider/callback' do
    it '初回はユーザー作成 & ログインする' do
      mock_omniauth(provider: 'github', uid: 'gh-1', name: 'GH User', email: 'gh@example.com')

      expect {
        get omni_auth_callback_path(provider: 'github')
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_present
    end

    it '2回目は作成されずログインのみ' do
      # 1回目で作成
      mock_omniauth(provider: 'github', uid: 'gh-1', name: 'GH User', email: 'gh@example.com')
      get omni_auth_callback_path(provider: 'github')

      # 2回目は作成されない
      mock_omniauth(provider: 'github', uid: 'gh-1', name: 'GH User', email: 'gh@example.com')
      expect {
        get omni_auth_callback_path(provider: 'github')
      }.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET /auth/failure' do
    it 'ログイン画面へリダイレクトする' do
      get omni_auth_failure_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
