# spec/factories/users.rb
FactoryBot.define do
  # === 基本ユーザー（fixtures: normal に対応） ===
  factory :user do
    name  { 'Normal' }                         # fixturesの値に合わせるなら固定でOK
    sequence(:email) { |n| "normal#{n}@example.com" }  # 重複回避（fixturesのunique相当）
    password              { 'password' }       # has_secure_password 用
    password_confirmation { 'password' }
    provider { nil }
    uid      { nil }
    admin    { false }

    # === Google ログインユーザー（fixtures: google_user に対応） ===
    factory :google_user do
      name     { 'Google Taro' }
      email    { 'taro@example.com' }
      provider { 'google_oauth2' }
      uid      { '12345' }
      # 外部ログインは password 不要。バリデーションを外している前提（has_secure_password validations: false）
      password              { nil }
      password_confirmation { nil }
      admin { false }
    end

    # === GitHub ログインユーザー（fixtures: github_user に対応） ===
    factory :github_user do
      name     { 'Octo' }
      email    { 'octo@example.com' }
      provider { 'github' }
      uid      { '99999' }
      password              { nil }
      password_confirmation { nil }
      admin { true }
    end
  end
end
