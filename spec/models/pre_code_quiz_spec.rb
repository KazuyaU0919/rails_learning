# spec/models/pre_code_quiz_spec.rb
require "rails_helper"

RSpec.describe PreCode, type: :model do
  it "answer が必須" do
    pc = build(:pre_code, answer: nil)
    expect(pc).to be_invalid
    expect(pc.errors[:answer]).to be_present
  end

  it "hint は 1000 文字以内" do
    pc = build(:pre_code, hint: "あ" * 1001, answer: "OK")
    expect(pc).to be_invalid
    expect(pc.errors[:hint]).to be_present
  end

  it "answer は 2000 文字以内" do
    pc = build(:pre_code, answer: "あ" * 2001)
    expect(pc).to be_invalid
    expect(pc.errors[:answer]).to be_present
  end

  it "有効な値なら保存できる" do
    pc = build(:pre_code, hint: "ヒント", answer: "解答")
    expect(pc).to be_valid
  end
end
