# spec/factories/tags.rb
FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag#{n}" }
    # zero_since は状況に応じてテスト内で明示設定
  end
end
