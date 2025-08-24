# spec/support/request_login_helper.rb
module RequestLoginHelper
  # 通常ログイン（/session#create）を通す想定
  def sign_in_as(user, password: "password")
    post session_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
    user
  end
end

RSpec.configure do |config|
  config.include RequestLoginHelper, type: :request
end
