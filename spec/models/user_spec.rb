# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  it '通常ユーザーのfactoryが有効' do
    expect(build(:user)).to be_valid
  end

  it 'Googleユーザーのfactoryが有効（password不要）' do
    u = build(:google_user)
    expect(u).to be_valid
  end

  it 'GitHubユーザーのfactoryが有効（admin: true）' do
    u = build(:github_user)
    expect(u.admin).to be true
    expect(u).to be_valid
  end
end
