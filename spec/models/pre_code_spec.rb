# spec/models/pre_code_spec.rb
require "rails_helper"

RSpec.describe PreCode, type: :model do
  describe "validations" do
    # 他の必須項目が満たされず検証に干渉しないよう、まともなインスタンスを用意
    subject { build(:pre_code) }

    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(50) }

    it "does not allow only whitespaces in title" do
      pre_code = build(:pre_code, title: "   ")
      expect(pre_code).to be_invalid
      expect(pre_code.errors[:title]).to be_present
    end

    # モデル側を 2000 に緩和したのでテストも合わせる
    it { should validate_length_of(:description).is_at_most(2000) }

    it { should validate_presence_of(:body) }
  end
end
