FactoryBot.define do
  factory :like do
    association :user
    association :pre_code
  end
end
