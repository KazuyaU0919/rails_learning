FactoryBot.define do
  factory :pre_code do
    association :user
    title       { "Sample Title" }
    description { "sample description" }
    body        { "puts 'hello world'" }
    like_count  { 0 }
    use_count   { 0 }
  end
end
