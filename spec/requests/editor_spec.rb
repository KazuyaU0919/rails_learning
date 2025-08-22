# spec/requests/editor_spec.rb
require "rails_helper"

RSpec.describe "Editor routing", type: :request do
  it "GET / returns 200" do
    get root_path
    expect(response).to have_http_status(:ok).or have_http_status(:no_content)
  end

  it "GET /pre_codes/:id/body returns 200" do
    get pre_code_body_path(1)
    expect(response).to have_http_status(:ok)
  end
end
