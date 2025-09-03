# spec/factories/authentications.rb
FactoryBot.define do
  factory :authentication do
    association :user
    provider { "google_oauth2" }
    sequence(:uid) { |n| "uid-#{n}" }

    trait :github do
      provider { "github" }
    end
  end
end
