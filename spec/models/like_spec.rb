# spec/models/like_spec.rb
require "rails_helper"

RSpec.describe Like, type: :model do
  let(:author) { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:u1)     { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:pc)     { create(:pre_code, user: author) }

  it "ユーザーとPreCodeがあれば有効" do
    expect(build(:like, user: u1, pre_code: pc)).to be_valid
  end

  it "同じユーザーが同じPreCodeに二重いいねはできない（ユニーク制約）" do
    create(:like, user: u1, pre_code: pc)
    dup = build(:like, user: u1, pre_code: pc)

    expect(dup).to be_invalid
  end

  it "作成/削除で pre_codes.like_count を自動加算/減算（counter_cache）" do
    expect { create(:like, user: u1, pre_code: pc) }
      .to change { pc.reload.like_count }.by(1)

    like = Like.find_by(user: u1, pre_code: pc)

    expect { like.destroy }
      .to change { pc.reload.like_count }.by(-1)
  end
end
