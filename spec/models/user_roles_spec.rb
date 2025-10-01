# spec/models/user_roles_spec.rb
require "rails_helper"

RSpec.describe User, type: :model do
  describe "#effective_role" do
    let(:user) { create(:user, admin: false, editor: false) }

    it "admin が最優先" do
      user.update!(admin: true, editor: false)
      expect(user.effective_role).to eq(:admin)
    end

    it "editor が次点" do
      user.update!(admin: false, editor: true)
      expect(user.effective_role).to eq(:editor)
    end

    it "sub_editor（個別権限あり）" do
      user.update!(admin: false, editor: false)
      create(:editor_permission, user:, target_type: "BookSection", target_id: 1, role: :sub_editor)
      expect(user.effective_role).to eq(:sub_editor)
    end

    it "上記いずれでもなければ general" do
      expect(user.effective_role).to eq(:general)
    end
  end

  describe "#can_edit?" do
    let!(:book)     { create(:book) }
    let!(:section)  { create(:book_section, book:, is_free: true, position: 1) }
    let!(:quiz)     { create(:quiz) }
    let!(:qsec)     { create(:quiz_section, quiz:, is_free: true, position: 1) }
    let!(:question) { create(:quiz_question, quiz:, quiz_section: qsec, position: 1) }

    it "admin は常に true" do
      admin = create(:user, admin: true)
      expect(admin.can_edit?(section)).to be true
      expect(admin.can_edit?(question)).to be true
    end

    it "editor は常に true" do
      editor = create(:user, editor: true)
      expect(editor.can_edit?(section)).to be true
      expect(editor.can_edit?(question)).to be true
    end

    it "sub_editor は対象に限り true" do
      sub = create(:user)
      create(:editor_permission, user: sub, target_type: "BookSection", target_id: section.id, role: :sub_editor)
      expect(sub.can_edit?(section)).to be true
      expect(sub.can_edit?(question)).to be false
    end

    it "general は false" do
      general = create(:user)
      expect(general.can_edit?(section)).to be false
    end
  end
end
