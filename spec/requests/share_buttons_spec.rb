# spec/requests/share_buttons_spec.rb
require "rails_helper"

RSpec.describe "ShareButtons", type: :request do
  let(:user)      { create(:user, password: "secret123", password_confirmation: "secret123") }
  let!(:pre_code) { create(:pre_code, user:, title: "シェアテスト") }

  it "PreCode詳細にシェアボタンが表示される（要ログイン）" do
    sign_in(user)
    get pre_code_path(pre_code)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Xでシェア")
    expect(response.body).to include("URLコピー")
  end

  it "CodeLibrary詳細にシェアボタンが表示される（未ログイン可）" do
    get code_library_path(pre_code)
    expect(response.body).to include("Xでシェア").and include("URLコピー")
  end

  it "クイズ結果画面にXでシェアが表示される" do
    quiz    = create(:quiz)
    section = create(:quiz_section, quiz:)
    get result_quiz_section_path(quiz, section)
    expect(response.body).to include("Xでシェア")
  end
end
