# spec/requests/likes_spec.rb
require "rails_helper"

RSpec.describe "Likes", type: :request do
  let(:user)     { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:pre_code) { create(:pre_code) }

  before { sign_in(user) }

  it "POST /likes 作成できる" do
    expect {
      post likes_path, params: { pre_code_id: pre_code.id }
    }.to change(Like, :count).by(1)
  end

  it "DELETE /likes/:id 削除できる" do
    like = user.likes.create!(pre_code: pre_code)
    expect {
      delete like_path(like)
    }.to change(Like, :count).by(-1)
  end
end
