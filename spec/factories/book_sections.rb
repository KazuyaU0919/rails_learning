# spec/factories/book_sections.rb
FactoryBot.define do
  factory :book_section do
    association :book
    sequence(:heading) { |n| "Section #{n}" }
    content            { "<p>body</p>" }
    is_free            { false }
    sequence(:position) { |n| n }

    trait :free do
      is_free { true }
    end
  end
end
