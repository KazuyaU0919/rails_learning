# spec/requests/collab_edit_book_sections_spec.rb
require "rails_helper"

RSpec.describe "Collaborative edit: BookSection", type: :request do
  let!(:book)    { create(:book) }
  let!(:section) { create(:book_section, book:, is_free: true, position: 1, content: "<p>old</p>") }

  let!(:editor)  { create(:user, admin: false, editor: false, password: "secret123", password_confirmation: "secret123") }
  let!(:admin)   { create(:user, admin: true,  editor: false, password: "secret123", password_confirmation: "secret123") }
  let!(:normal)  { create(:user, admin: false, editor: false, password: "secret123", password_confirmation: "secret123") }

  before do
    # enum は sub_editor のみ
    EditorPermission.create!(user: editor, target_type: "BookSection", target_id: section.id, role: :sub_editor)
  end

  describe "閲覧/編集リンク" do
    it "権限ユーザーには編集リンクが見える" do
      sign_in(editor)
      get book_section_path(book, section)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_book_section_path(book, section))
    end

    it "一般ユーザーには編集リンクが出ない" do
      sign_in(normal)
      get book_section_path(book, section)
      expect(response.body).not_to include(edit_book_section_path(book, section))
    end
  end

  describe "編集可否" do
    it "権限ユーザーは編集できる" do
      sign_in(editor)
      get edit_book_section_path(book, section)
      expect(response).to have_http_status(:ok)

      expect {
        patch book_section_path(book, section), params: {
          book_section: { content: "<p>updated</p>", lock_version: section.lock_version }
        }
      }.to change { section.reload.content }.to("<p>updated</p>")

      expect(response).to redirect_to(book_section_path(book, section))
    end

    it "管理者は権限付与がなくても編集できる" do
      sign_in(admin)
      patch book_section_path(book, section), params: {
        book_section: { content: "<p>admin</p>", lock_version: section.lock_version }
      }
      expect(response).to redirect_to(book_section_path(book, section))
      expect(section.reload.content).to eq("<p>admin</p>")
    end

    it "一般ユーザーは 302（権限なし）" do
      sign_in(normal)
      get edit_book_section_path(book, section)
      expect(response).to have_http_status(:found).or have_http_status(:see_other)
    end
  end

  describe "サニタイズ/許可属性" do
    it "script タグは除去される" do
      sign_in(editor)
      patch book_section_path(book, section), params: {
        book_section: { content: %(<p>a</p><script>alert(1)</script>), lock_version: section.lock_version }
      }
      follow_redirect!
      expect(response.body).to include("<p>a</p>")
      expect(response.body).not_to include("<script>")
    end

    it "position 等は更新できない（一般編集者）" do
      sign_in(editor)
      original = section.position
      patch book_section_path(book, section), params: {
        book_section: {
          content: "<p>keep</p>",
          position: original + 5,      # 許可されていない
          lock_version: section.lock_version
        }
      }
      expect(section.reload.position).to eq(original)
      expect(section.content).to eq("<p>keep</p>")
    end
  end

  describe "PaperTrail" do
    it "更新すると version が増える" do
      sign_in(editor)
      expect {
        patch book_section_path(book, section), params: {
          book_section: { content: "<p>v2</p>", lock_version: section.lock_version }
        }
      }.to change { section.reload.versions.count }.by(1)
    end
  end

  describe "optimistic locking" do
    it "ロック競合時は 409 で、内容は更新されない" do
      sign_in(editor)

      section.update!(content: "v1")
      stale = section.reload.lock_version
      section.update!(content: "v2") # lock_version 前進

      expect {
        patch book_section_path(book, section), params: {
          book_section: { content: "v3", lock_version: stale }
        }
        expect(response).to have_http_status(:conflict)
      }.not_to change { section.reload.content }
      expect(response.body).to include("競合")
    end
  end
end
