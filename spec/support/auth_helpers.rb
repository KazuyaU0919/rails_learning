# spec/support/auth_helpers.rb
# リクエストスペック用のログインヘルパ
module AuthHelpers
  # 既存スペック互換: sign_in(user, password: "secret123")
  # 追加シンタックス:  sign_in_as(user, password: "xxxx")
  def sign_in(user = nil, password: "secret123", as: nil)
    user ||= as
    raise ArgumentError, "user を指定してください" unless user

    post session_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end
  alias_method :sign_in_as, :sign_in
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
