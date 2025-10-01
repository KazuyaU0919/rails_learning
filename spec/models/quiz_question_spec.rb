# spec/models/quiz_question_spec.rb
require "rails_helper"

RSpec.describe QuizQuestion, type: :model do
  let(:quiz)    { create(:quiz) }
  let(:section) { create(:quiz_section, quiz:) }

  def build_question(attrs = {})
    build(:quiz_question, { quiz:, quiz_section: section }.merge(attrs))
  end

  describe "基本の妥当性" do
    it "ファクトリは有効" do
      expect(build_question).to be_valid
    end
  end

  describe "バリデーション" do
    it "question/explanation は必須" do
      q = build_question(question: "", explanation: "")
      expect(q).to be_invalid
      expect(q.errors[:question]).to be_present
      expect(q.errors[:explanation]).to be_present
    end

    it "choice1..4 は全て必須" do
      q = build_question(choice1: "", choice2: "", choice3: "", choice4: "")
      expect(q).to be_invalid
      expect(q.errors[:choice1]).to be_present
      expect(q.errors[:choice2]).to be_present
      expect(q.errors[:choice3]).to be_present
      expect(q.errors[:choice4]).to be_present
    end

    it "correct_choice は 1..4 のみ許可（0,5,nil はNG）" do
      [ 0, 5, nil ].each do |v|
        q = build_question(correct_choice: v)
        expect(q).to be_invalid
        expect(q.errors[:correct_choice]).to be_present
      end
      expect(build_question(correct_choice: 1)).to be_valid
      expect(build_question(correct_choice: 4)).to be_valid
    end

    it "position は 1 以上の整数" do
      [ -1, 0, 1.5, nil ].each do |v|
        q = build_question(position: v)
        expect(q).to be_invalid
        expect(q.errors[:position]).to be_present
      end
      expect(build_question(position: 1)).to be_valid
      expect(build_question(position: 2)).to be_valid
    end
  end

  describe "関連" do
    it "quiz / quiz_section に属する" do
      q = build_question
      expect(q.quiz).to eq(quiz)
      expect(q.quiz_section).to eq(section)
    end
  end
end
