# spec/factories/pre_codes.rb
FactoryBot.define do
  factory :pre_code do
    association :user
    sequence(:title) { |n| "Sample Title #{n}" }
    description      { "sample description" }
    body             { "puts 'hello world'" }
    like_count       { 0 }
    use_count        { 0 }
    hint        { "これはヒントです" }    # 任意
    answer      { "これは解答です" }      # 必須
    answer_code  { "puts 'answer code example'" }
  end

  factory :pre_code_sample, parent: :pre_code do
    title       { "サンプル#{SecureRandom.hex(2)}" }
    description { "説明テキスト" }
    body        { "puts 'hello'" }
    hint        { "サンプルのヒント" }
    answer      { "サンプルの解答" }
  end
end
