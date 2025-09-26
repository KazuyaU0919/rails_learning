# app/models/pre_code_tagging.rb
class PreCodeTagging < ApplicationRecord
  belongs_to :pre_code
  belongs_to :tag, counter_cache: :taggings_count

  validates :pre_code_id, uniqueness: { scope: :tag_id }
end
