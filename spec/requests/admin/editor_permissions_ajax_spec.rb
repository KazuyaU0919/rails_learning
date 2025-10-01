# spec/requests/admin/editor_permissions_ajax_spec.rb
require "rails_helper"

RSpec.describe "Admin::EditorPermissions Ajax", type: :request do
  let!(:admin) { create(:user, admin: true) }

  before { sign_in(admin) }

  describe "GET /admin/editor_permissions/describe_target" do
    it "BookSection を整形して返す" do
      book = create(:book, title: "B")
      sec  = create(:book_section, book:, heading: "H")
      get describe_target_admin_editor_permissions_path, params: { target_type: "BookSection", target_id: sec.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["label"]).to include("BookSection##{sec.id}")
      expect(json["label"]).to include("B").and include("H")
    end

    it "見つからない時でもベース表記を返す" do
      get describe_target_admin_editor_permissions_path, params: { target_type: "QuizQuestion", target_id: 999_999 }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["label"]).to eq("QuizQuestion#999999（見つかりません）")
    end
  end

  describe "GET /admin/editor_permissions/user_status" do
    it "admin を判定" do
      get user_status_admin_editor_permissions_path, params: { user_id: admin.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("ok" => true, "admin" => true, "editor" => false)
      expect(json["label"]).to eq("管理者")
    end

    it "editor を判定" do
      editor = create(:user, editor: true)
      get user_status_admin_editor_permissions_path, params: { user_id: editor.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("ok" => true, "admin" => false, "editor" => true)
      expect(json["label"]).to eq("編集者")
    end

    it "一般ユーザー" do
      u = create(:user)
      get user_status_admin_editor_permissions_path, params: { user_id: u.id }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("ok" => true, "admin" => false, "editor" => false)
      expect(json["label"]).to be_nil
    end
  end
end
