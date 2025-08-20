FactoryBot.define do
  factory :used_code do
    association :user
    association :pre_code
    used_at { Time.current }
  end
end
