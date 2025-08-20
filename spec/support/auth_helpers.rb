# spec/support/auth_helpers.rb

# ログイン用の小ヘルパ（リクエストスペックから呼ぶ）
module AuthHelpers
  def sign_in(user, password: "secret123")
    post session_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
