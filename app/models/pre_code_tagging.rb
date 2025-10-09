# app/models/pre_code_tagging.rb
class PreCodeTagging < ApplicationRecord
  belongs_to :pre_code
  belongs_to :tag, counter_cache: :taggings_count

  validates :pre_code_id, uniqueness: { scope: :tag_id }

  # counter_cache 更新が走った“後”で zero_since を整合
  after_commit :refresh_tag_zero_since!, on: [ :create, :destroy ]

  private

  def refresh_tag_zero_since!
    # リロードして最新の taggings_count を見てから更新
    tag.reload
    tag.refresh_zero_since!
  end
end
