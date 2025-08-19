# spec/support/omniauth.rb
require 'omniauth'

OmniAuth.config.test_mode = true

def mock_omniauth(provider:, uid: "u-123", name: "Mock User", email: "mock@example.com")
  OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new(
    provider: provider,
    uid: uid,
    info: { name: name, email: email }
  )
end
