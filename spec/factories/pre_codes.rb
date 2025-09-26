# spec/factories/pre_codes.rb
FactoryBot.define do
  factory :pre_code do
    association :user
    sequence(:title)       { |n| "Sample Title #{n}" }   # 衝突しにくいように連番化
    description            { "sample description" }
    body                   { "puts 'hello world'" }
    like_count             { 0 }
    use_count              { 0 }
  end

  # One-pager のサンプル値に合わせた派生ファクトリ
  factory :pre_code_sample, parent: :pre_code do
    title       { "サンプル#{SecureRandom.hex(2)}" }
    description { "説明テキスト" }
    body        { "puts 'hello'" }
  end
end
