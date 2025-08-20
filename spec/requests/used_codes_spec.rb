# spec/requests/used_codes_spec.rb
require "rails_helper"

RSpec.describe "UsedCodes", type: :request do
  let(:user)     { create(:user, password: "secret123", password_confirmation: "secret123") }
  let(:pre_code) { create(:pre_code) }

  before { sign_in(user) }

  it "POST /used_codes で利用記録が1件作成される" do
    expect {
      post used_codes_path, params: { pre_code_id: pre_code.id }
    }.to change(UsedCode, :count).by(1)
  end
end
