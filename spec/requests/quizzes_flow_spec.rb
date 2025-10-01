# spec/requests/quizzes_flow_spec.rb
require "rails_helper"

RSpec.describe "Quizzes (flow)", type: :request do
  let!(:quiz)     { create(:quiz, title: "計算クイズ") }
  let!(:section)  { create(:quiz_section, quiz:, is_free: true, position: 1, heading: "1-1") }

  # 1問目: 正解は 4 / 2問目: 正解は 3
  let!(:q1) do
    create(:quiz_question, quiz:, quiz_section: section,
           position: 1, question: "2+2=?",
           choice1: "1", choice2: "2", choice3: "3", choice4: "4",
           correct_choice: 4, explanation: "2+2=4")
  end
  let!(:q2) do
    create(:quiz_question, quiz:, quiz_section: section,
           position: 2, question: "1+2=?",
           choice1: "1", choice2: "2", choice3: "3", choice4: "4",
           correct_choice: 3, explanation: "1+2=3")
  end

  describe "FREE セクションは未ログインでも解ける → 結果まで到達できる" do
    it "質問ページ表示 → 解答（PRG追従）→ 解説に“正解/不正解”→ 結果で集計" do
      # 最初の設問へ
      get quiz_section_question_path(quiz, section, q1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Q1")

      # 1問目: 正解を送信（PRGなので follow_redirect! で GET に追従）
      post answer_quiz_section_question_path(quiz, section, q1), params: { choice: 4 }
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("正解")        # 正解表示
      expect(response.body).to include("解説")        # 解説表示

      # 2問目: 不正解を送信 → 解説で“不正解”
      post answer_quiz_section_question_path(quiz, section, q2), params: { choice: 1 }
      expect(response).to have_http_status(:see_other)
      follow_redirect!
      expect(response.body).to include("不正解")

      # 結果ページ
      get result_quiz_section_path(quiz, section)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("1").and include("/ 2").and include("正解")
    end
  end

  describe "セクション show は最初の問題に誘導される" do
    it "show にアクセスすると 1問目へリダイレクト" do
      get quiz_section_path(quiz, section)
      expect(response).to have_http_status(:found).or have_http_status(:see_other)
      follow_redirect!
      # 1問目の質問文 or 番号が出ていることをざっくり確認
      expect(response.body).to include("Q1").or include("2+2=?")
    end
  end

  describe "有料（is_free:false）セクションは未ログインだとログイン画面へ" do
    let!(:paid_section) { create(:quiz_section, quiz:, is_free: false, position: 2, heading: "1-2") }
    let!(:paid_q) do
      create(:quiz_question, quiz:, quiz_section: paid_section, position: 1)
    end

    it "質問ページにアクセスするとログインへリダイレクト" do
      get quiz_section_question_path(quiz, paid_section, paid_q)
      expect(response).to have_http_status(:found).or have_http_status(:see_other)
      # アプリのログインルート名が異なる場合はここを変更してください
      expect(response).to redirect_to(new_session_path)
    end
  end
end
