# spec/requests/collab_edit_quiz_questions_spec.rb
require "rails_helper"

RSpec.describe "Collaborative edit: QuizQuestion", type: :request do
  let!(:quiz)     { create(:quiz) }
  let!(:section)  { create(:quiz_section, quiz:, is_free: true, position: 1) }
  let!(:question) { create(:quiz_question, quiz:, quiz_section: section, position: 1, question: "Q1") }

  let!(:editor)   { create(:user, password: "secret123", password_confirmation: "secret123") }
  let!(:admin)    { create(:user, admin: true, password: "secret123", password_confirmation: "secret123") }
  let!(:normal)   { create(:user, password: "secret123", password_confirmation: "secret123") }

  before do
    EditorPermission.create!(user: editor, target_type: "QuizQuestion", target_id: question.id, role: :sub_editor)
  end

  describe "編集" do
    it "権限ユーザーは問題を更新できる" do
      sign_in(editor)

      expect {
        patch quiz_section_question_path(quiz, section, question), params: {
          quiz_question: { question: "書き換え？", explanation: "exp", lock_version: question.lock_version }
        }
      }.to change { question.reload.question }.to("書き換え？")

      expect(response).to redirect_to(quiz_section_question_path(quiz, section, question))
      follow_redirect!
      expect(response.body).to include("書き換え？")
    end

    it "管理者は権限無しでも更新できる" do
      sign_in(admin)
      patch quiz_section_question_path(quiz, section, question), params: {
        quiz_question: { question: "admin update", lock_version: question.lock_version }
      }
      expect(response).to redirect_to(quiz_section_question_path(quiz, section, question))
      expect(question.reload.question).to eq("admin update")
    end

    it "一般ユーザーは 302（権限なし）" do
      sign_in(normal)
      patch quiz_section_question_path(quiz, section, question), params: {
        quiz_question: { question: "nope", lock_version: question.lock_version }
      }
      expect(response).to have_http_status(:found).or have_http_status(:see_other)
      expect(question.reload.question).to eq("Q1")
    end
  end

  describe "許可属性のみ更新" do
    it "position は更新されない" do
      sign_in(editor)
      original = question.position
      patch quiz_section_question_path(quiz, section, question), params: {
        quiz_question: {
          question: "keep",
          position: original + 10, # 許可されていない
          lock_version: question.lock_version
        }
      }
      expect(question.reload.position).to eq(original)
      expect(question.question).to eq("keep")
    end
  end

  describe "PaperTrail" do
    it "更新で version が増える" do
      sign_in(editor)
      expect {
        patch quiz_section_question_path(quiz, section, question), params: {
          quiz_question: { question: "v2", lock_version: question.lock_version }
        }
      }.to change { question.reload.versions.count }.by(1)
    end
  end

  describe "optimistic locking" do
    it "ロック競合は 409" do
      sign_in(editor)
      question.update!(question: "v1")
      stale = question.reload.lock_version
      question.update!(question: "v2")

      patch quiz_section_question_path(quiz, section, question), params: {
        quiz_question: { question: "v3", lock_version: stale }
      }
      expect(response).to have_http_status(:conflict)
      expect(question.reload.question).to eq("v2")
    end
  end
end
