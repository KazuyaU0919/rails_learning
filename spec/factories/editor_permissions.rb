# spec/factories/editor_permissions.rb
FactoryBot.define do
  factory :editor_permission do
    association :user
    target_type { "BookSection" }
    sequence(:target_id) { |n| n }
    role { :sub_editor }  # ← enum は sub_editor のみ

    trait :for_book_section do
      target_type { "BookSection" }
    end

    trait :for_quiz_question do
      target_type { "QuizQuestion" }
    end
  end
end
