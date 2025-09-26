# app/models/bookmark.rb
class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :pre_code

  validates :user_id, uniqueness: { scope: :pre_code_id }
end
