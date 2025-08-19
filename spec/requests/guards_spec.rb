# spec/requests/guards_spec.rb
require 'rails_helper'

RSpec.describe "Guards", type: :request do
  let(:user) { create(:user) }

  # 現状、ログイン時のみしか閲覧できないページがないためコメントアウト！
  # it "未ログインで保護ページに行くとログイン画面へ" do
  #   get "/account" # 例: require_login! を貼っているパス
  #   expect(response).to redirect_to(new_session_path)
  #   follow_redirect!
  #   expect(response.body).to include("ログインしてください")
  # end

  it "ログイン中に /session/new へ行くと root へ" do
    post session_path, params: { email: user.email, password: "password" }
    get new_session_path
    expect(response).to redirect_to(root_path)
  end
end
