# spec/requests/sessions_spec.rb
require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let!(:user) { create(:user, email: 'login@example.com', password: 'password', password_confirmation: 'password') }

  describe 'GET /session/new' do
    it '200 が返る' do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /session' do
    it '正しい情報でログインできる' do
      post session_path, params: { email: user.email, password: 'password' }
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(root_path)
    end

    it '誤った情報なら 422' do
      post session_path, params: { email: user.email, password: 'wrong' }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:user_id]).to be_blank
    end
  end

  describe 'DELETE /session' do
    it 'ログアウトできる' do
      # 先にログイン
      post session_path, params: { email: user.email, password: 'password' }
      delete session_path
      expect(response).to redirect_to(root_path)
      expect(session[:user_id]).to be_blank
    end
  end
end
