# spec/models/authentication_spec.rb
require "rails_helper"

RSpec.describe Authentication, type: :model do
  it "有効なfactoryを持つ" do
    expect(build(:authentication)).to be_valid
  end

  it "user, provider, uid は必須" do
    expect(build(:authentication, user: nil)).to be_invalid
    expect(build(:authentication, provider: nil)).to be_invalid
    expect(build(:authentication, uid: nil)).to be_invalid
  end

  it "同一(provider, uid) は世界で一意" do
    a1 = create(:authentication, provider: "google_oauth2", uid: "X")
    a2 = build(:authentication, provider: a1.provider, uid: a1.uid)
    expect(a2).to be_invalid
  end

  it "同一ユーザーが同じproviderを二重に持てない" do
    user = create(:user)
    create(:authentication, user:, provider: "github", uid: "G-1")
    dup  = build(:authentication, user:, provider: "github", uid: "G-2")
    expect(dup).to be_invalid
  end

  it "for_provider スコープで絞れる" do
    g = create(:authentication, provider: "google_oauth2")
    create(:authentication, provider: "github")
    expect(Authentication.for_provider("google_oauth2")).to match_array([ g ])
  end
end
