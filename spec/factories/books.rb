# spec/factories/books.rb
FactoryBot.define do
  factory :book do
    sequence(:title)       { |n| "Rails Book #{n}" }
    description            { "This is a sample book." }
    sequence(:position)    { |n| n }
  end
end
