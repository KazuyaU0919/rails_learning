# spec/requests/static_pages_spec.rb
require "rails_helper"

RSpec.describe "StaticPages", type: :request do
  it { get help_path;    expect(response).to have_http_status(:ok) }
  it { get terms_path;   expect(response).to have_http_status(:ok) }
  it { get privacy_path; expect(response).to have_http_status(:ok) }
  it { get contact_path; expect(response).to have_http_status(:ok) }
end
