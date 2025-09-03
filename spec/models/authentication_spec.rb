# spec/models/authentication_spec.rb
require "rails_helper"

RSpec.describe Authentication, type: :model do
  describe "validations" do
    it "有効なfactoryを持つ" do
      expect(build(:authentication)).to be_valid
    end

    it "user / provider / uid は必須" do
      expect(build(:authentication, user: nil)).to be_invalid
      expect(build(:authentication, provider: nil)).to be_invalid
      expect(build(:authentication, uid: nil)).to be_invalid
    end

    it "同一 (provider, uid) はグローバルに一意" do
      create(:authentication, provider: "google_oauth2", uid: "X")
      dup = build(:authentication, provider: "google_oauth2", uid: "X")
      expect(dup).to be_invalid
    end

    it "同一ユーザーは同じ provider を二重に持てない" do
      user = create(:user, password: "secret123", password_confirmation: "secret123")
      create(:authentication, user:, provider: "github", uid: "G-1")
      dup = build(:authentication, user:, provider: "github", uid: "G-2")
      expect(dup).to be_invalid
    end
  end

  describe "scopes" do
    it "for_provider で provider を絞り込める" do
      g = create(:authentication, provider: "google_oauth2")
      create(:authentication, provider: "github")
      expect(Authentication.for_provider("google_oauth2")).to match_array([ g ])
    end
  end
end
