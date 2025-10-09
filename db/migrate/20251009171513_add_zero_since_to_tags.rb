class AddZeroSinceToTags < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :zero_since, :datetime
    add_index  :tags, :zero_since
    add_index  :tags, :taggings_count
  end
end
