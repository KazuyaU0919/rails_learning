# spec/support/omniauth.rb
require "omniauth"

OmniAuth.config.test_mode = true

def mock_omniauth(provider:, uid: "u-123", name: "Mock User", email: "mock@example.com")
  hash = OmniAuth::AuthHash.new(
    provider: provider,
    uid:      uid,
    info:     { name:, email: }
  )

  # 1) /auth/:provider ルート → ミドルウェアが mock_auth を参照
  OmniAuth.config.mock_auth[provider.to_sym] = hash

  # 2) /auth/:provider/callback を直接叩くテスト → controller が env を参照
  Rails.application.env_config["omniauth.auth"] = hash
end

RSpec.configure do |config|
  config.after(:each) do
    Rails.application.env_config.delete("omniauth.auth")
  end
end
