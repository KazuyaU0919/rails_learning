# spec/factories/bookmarks.rb
FactoryBot.define do
  factory :bookmark do
    association :user
    association :pre_code
  end
end
