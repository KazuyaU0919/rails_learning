# spec/factories/pre_code_taggings.rb
FactoryBot.define do
  factory :pre_code_tagging do
    association :pre_code
    association :tag
  end
end
