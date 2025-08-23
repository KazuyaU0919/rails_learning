class AddBookSectionsCountToBooks < ActiveRecord::Migration[8.0]
  def up
    add_column :books, :book_sections_count, :integer, null: false, default: 0
    Book.reset_column_information

    # 既存データを埋め直し
    Book.find_each { |b| Book.reset_counters(b.id, :book_sections) }
  end

  def down
    remove_column :books, :book_sections_count
  end
end
