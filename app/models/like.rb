# app/models/like.rb
class Like < ApplicationRecord
  belongs_to :user
  belongs_to :pre_code, counter_cache: :like_count

  validates :user_id, uniqueness: { scope: :pre_code_id }
end
