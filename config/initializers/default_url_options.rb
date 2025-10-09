# config/initializers/default_url_options.rb

if Rails.env.development?
  options = { host: "localhost", port: 3000, protocol: "http" }
else
  host = ENV.fetch("APP_HOST", "example.com")
  options = { host:, protocol: "https" }
end

# ルーティングURL生成
Rails.application.routes.default_url_options = options

# メールURL生成
ActionMailer::Base.default_url_options = options
