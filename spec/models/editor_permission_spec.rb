# spec/models/editor_permission_spec.rb
require "rails_helper"

RSpec.describe EditorPermission, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "enums" do
    it "role は sub_editor を持つ" do
      expect(described_class.roles.keys).to contain_exactly("sub_editor")
    end
  end

  describe "validations" do
    subject(:perm) { build(:editor_permission, user:, target_type: "BookSection", target_id: 1, role: :sub_editor) }
    let(:user) { create(:user) }

    it { is_expected.to validate_presence_of(:target_type) }
    it { is_expected.to validate_presence_of(:target_id) }

    it "target_id は数値のみ" do
      perm.target_id = "abc"
      expect(perm).to be_invalid
      expect(perm.errors[:target_id]).to be_present
    end

    it "有効" do
      expect(perm).to be_valid
    end

    it "user/target のユニーク制約（DBレベル）" do
      described_class.create!(user:, target_type: "BookSection", target_id: 123, role: :sub_editor)
      expect {
        described_class.create!(user:, target_type: "BookSection", target_id: 123, role: :sub_editor)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#target_human_label" do
    it "対象が存在しない場合はベース表記" do
      perm = build(:editor_permission, target_type: "BookSection", target_id: 999_999)
      expect(perm.target_human_label).to eq("BookSection#999999")
    end
  end
end
