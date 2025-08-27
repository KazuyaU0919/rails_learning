# spec/factories/users.rb
FactoryBot.define do
  # === 基本ユーザー（通常登録） ===
  factory :user do
    name  { "Normal" }
    sequence(:email) { |n| "normal#{n}@example.com" }
    password              { "password" }
    password_confirmation { "password" }
    provider { nil }
    uid      { nil }
    admin    { false }
  end

  # === Google ログインユーザー（OAuth） ===
  factory :google_user, class: "User" do
    name  { "Google Taro" }
    email { "taro@example.com" }
    provider { "google_oauth2" }
    uid      { "g-#{SecureRandom.hex(4)}" }
    password              { nil }
    password_confirmation { nil }
    admin { false }
  end

  # === GitHub ログインユーザー（OAuth, 管理者想定） ===
  factory :github_user, class: "User" do
    name  { "Octo" }
    email { "octo@example.com" }
    provider { "github" }
    uid      { "gh-#{SecureRandom.hex(4)}" }
    password              { nil }
    password_confirmation { nil }
    admin { true }
  end
end
