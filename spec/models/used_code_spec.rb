# spec/models/used_code_spec.rb
require "rails_helper"

RSpec.describe UsedCode, type: :model do
  let(:author) { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:u1)     { create(:user,  password: "secret123", password_confirmation: "secret123") }
  let(:pc)     { create(:pre_code, user: author) }

  it "ユーザーとPreCodeがあれば有効" do
    expect(build(:used_code, user: u1, pre_code: pc)).to be_valid
  end

  it "作成時に used_at が自動セットされる（before_validation）" do
    uc = create(:used_code, user: u1, pre_code: pc, used_at: nil)
    expect(uc.used_at).to be_present
  end

  it "同じユーザーは同じPreCodeを二重記録できない（ユニーク制約）" do
    create(:used_code, user: u1, pre_code: pc)
    dup = build(:used_code, user: u1, pre_code: pc)

    expect(dup).to be_invalid
  end

  it "作成で pre_codes.use_count を自動加算（counter_cache）" do
    expect { create(:used_code, user: u1, pre_code: pc) }
      .to change { pc.reload.use_count }.by(1)
  end
end
