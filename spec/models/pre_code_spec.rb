# spec/models/pre_code_spec.rb
require "rails_helper"

RSpec.describe PreCode, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(50) }

    it "does not allow only whitespaces in title" do
      pre_code = build(:pre_code, title: "   ")
      expect(pre_code).to be_invalid
      expect(pre_code.errors[:title]).to be_present
    end

    it { should validate_length_of(:description).is_at_most(500) }
    it { should validate_presence_of(:body) }
  end
end
