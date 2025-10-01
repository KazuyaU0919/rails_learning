# spec/factories/quizzes.rb
FactoryBot.define do
  factory :quiz do
    sequence(:title) { |n| "Quiz #{n}" }
    description { "desc" }
    position { 1 }
  end

  factory :quiz_section do
    association :quiz
    sequence(:heading) { |n| "Section #{n}" }
    is_free { true }
    position { 1 }
  end

  factory :quiz_question do
    association :quiz
    association :quiz_section
    sequence(:position) { |n| n }
    question { "2+2= ?" }
    choice1  { "1" }
    choice2  { "2" }
    choice3  { "3" }
    choice4  { "4" }
    correct_choice { 4 }
    explanation { "2+2=4" }
  end
end
