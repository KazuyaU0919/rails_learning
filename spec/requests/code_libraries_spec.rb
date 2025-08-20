# spec/requests/code_libraries_spec.rb
require "rails_helper"

RSpec.describe "CodeLibraries", type: :request do
  let(:user) { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:mine) { create(:pre_code, user: user) }

  it "自分のデータは /pre_codes にリダイレクト" do
    sign_in(user)
    get code_library_path(mine)
    expect(response).to redirect_to(pre_codes_path)
  end
end
