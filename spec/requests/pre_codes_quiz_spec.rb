# spec/requests/pre_codes_quiz_spec.rb
require "rails_helper"

RSpec.describe "PreCodes (Quiz)", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  it "解答が空だと 422 で失敗する" do
    params = attributes_for(:pre_code).merge(answer: nil, hint: "h")
    post pre_codes_path, params: { pre_code: params }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "作成時に hint/answer が保存される" do
    params = attributes_for(:pre_code).merge(hint: "ヒント", answer: "解答")
    post pre_codes_path, params: { pre_code: params }
    expect(response).to have_http_status(:found)
    pc = PreCode.order(:id).last
    expect(pc.hint).to include("ヒント")
    expect(pc.answer).to include("解答")
  end

  it "保存前にサニタイズされる" do
    params = attributes_for(:pre_code).merge(
      hint:   %(<script>alert(1)</script><b>ok</b>),
      answer: %(<img src=x onerror=alert(1)>safe)
    )
    post pre_codes_path, params: { pre_code: params }
    pc = PreCode.order(:id).last
    expect(pc.hint).to include("<b>ok</b>")
    expect(pc.hint).not_to include("<script>")
    expect(pc.answer).to include("safe")
    expect(pc.answer).not_to include("onerror")
  end

  it "更新でも同様に動作する" do
    pc = create(:pre_code, user:, answer: "x")
    patch pre_code_path(pc), params: { pre_code: { answer: "y", hint: "h2" } }
    expect(response).to have_http_status(:found)
    expect(pc.reload.answer).to eq("y")
    expect(pc.reload.hint).to eq("h2")
  end
end
