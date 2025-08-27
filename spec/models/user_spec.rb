# spec/models/user_spec.rb
require "rails_helper"

RSpec.describe User, type: :model do
  it "通常ユーザーのfactoryが有効" do
    expect(build(:user)).to be_valid
  end

  it "Googleユーザーのfactoryが有効（password不要）" do
    u = build(:google_user)
    expect(u).to be_valid
  end

  it "GitHubユーザーのfactoryが有効（admin: true）" do
    u = build(:github_user)
    expect(u.admin).to be true
    expect(u).to be_valid
  end

  describe "email の一意性（通常登録のみ）" do
    it "email の一意性（通常登録のみ） case-insensitive に重複を弾く（provider: nil 同士）" do
      create(:user, email: "ALICE@example.com")
      u = build(:user, email: "alice@EXAMPLE.com")

      u.validate
      expect(u).to be_invalid
      expect(u.errors.of_kind?(:email, :taken)).to be true
    end

    it "OAuthユーザーが同じメールでも、OAuth側は uniqueness 対象外" do
      create(:user, email: "same@example.com")
      oauth = build(:google_user, email: "same@example.com")
      expect(oauth).to be_valid
    end
  end
end
