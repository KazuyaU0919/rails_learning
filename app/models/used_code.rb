# app/models/used_code.rb
class UsedCode < ApplicationRecord
  belongs_to :user
  belongs_to :pre_code, counter_cache: :use_count

  validates :used_at, presence: true
  validates :user_id, uniqueness: { scope: :pre_code_id }

  before_validation :set_used_at, on: :create
  private
  def set_used_at
    self.used_at ||= Time.current
  end
end
