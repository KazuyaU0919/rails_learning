# spec/requests/password_resets_spec.rb
require 'rails_helper'

RSpec.describe 'PasswordResets', type: :request do
  describe 'GET /password_resets/new' do
    it '200 が返る' do
      get new_password_reset_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /password_resets/:token/edit' do
    it '（仮）ダミートークンでも 200 が返る' do
      # 実装後は有効なトークンで検証する
      get edit_password_reset_path('dummy-token')
      expect(response).to have_http_status(:ok)
    end
  end
end
