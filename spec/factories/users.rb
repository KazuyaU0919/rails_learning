# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:name)  { |n| "User#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password              { "secret123" }
    password_confirmation { "secret123" }
    admin { false }
  end

  # OAuthユーザー（Google）
  factory :google_user, parent: :user do
    # 「password不要」を満たす
    password              { nil }
    password_confirmation { nil }

    # build時点でOAuth判定に入るようにする（createではなくbuild）
    after(:build) do |user|
      # has_many :authentications 前提（モデルに合わせて名称を変えてください）
      user.authentications.build(
        provider: "google_oauth2",
        uid:      "uid-#{SecureRandom.hex(4)}"
      )
    end
  end

  # OAuthユーザー（GitHub, admin: true）
  factory :github_user, parent: :user do
    admin { true }
    password              { nil }
    password_confirmation { nil }

    after(:build) do |user|
      user.authentications.build(
        provider: "github",
        uid:      "uid-#{SecureRandom.hex(4)}"
      )
    end
  end
end
