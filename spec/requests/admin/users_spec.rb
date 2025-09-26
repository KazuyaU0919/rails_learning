require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let!(:target) { create(:user) }
  let!(:admin)  { create(:user, admin: true) }

  before { sign_in admin }

  describe "GET /admin/users" do
    it "一覧に作成したユーザーが表示される" do
      target # ← 先に生成
      get admin_users_path
      expect(response.body).to include(target.email)
    end
  end

  describe "PATCH /toggle_editor" do
    it "編集者権限を切替できる" do
      patch toggle_editor_admin_user_path(target)
      expect(target.reload.editor).to eq(true)
    end
  end

  describe "PATCH /toggle_ban" do
    it "BANを設定できる" do
      patch toggle_ban_admin_user_path(target), params: { ban_reason: "test" }
      expect(target.reload).to be_banned
    end
  end

  describe "DELETE /users/:id" do
    it "ユーザーを削除できる" do
      delete admin_user_path(target)
      expect(User.exists?(target.id)).to eq(false)
    end
  end
end
