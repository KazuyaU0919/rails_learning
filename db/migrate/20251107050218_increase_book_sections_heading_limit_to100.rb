class IncreaseBookSectionsHeadingLimitTo100 < ActiveRecord::Migration[8.1]
  def up
    change_column :book_sections, :heading, :string, limit: 100, null: false
  end

  def down
    change_column :book_sections, :heading, :string, limit: 50, null: false
  end
end
