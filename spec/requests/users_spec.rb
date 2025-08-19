# spec/requests/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /users/new' do
    it '200 が返る' do
      get new_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /users' do
    it '新規登録できてログイン状態になる' do
      params = {
        user: {
          name: 'テスト太郎',
          email: 'taro@example.com',
          password: 'password',
          password_confirmation: 'password'
        }
      }

      expect {
        post users_path, params: params
      }.to change(User, :count).by(1)

      expect(session[:user_id]).to be_present
      expect(response).to redirect_to(root_path)
    end

    it 'バリデーションエラーなら 422 で件数は増えない' do
      bad = { user: { name: '', email: 'bad', password: '1', password_confirmation: '2' } }

      expect {
        post users_path, params: bad
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
