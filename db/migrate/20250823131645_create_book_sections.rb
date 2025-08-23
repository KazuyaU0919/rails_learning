class CreateBookSections < ActiveRecord::Migration[8.0]
  def change
    create_table :book_sections do |t|
      t.references :book, null: false, foreign_key: true, index: true
      t.string  :heading,  null: false
      t.text    :content,  null: false
      t.boolean :is_free,  null: false, default: false
      t.integer :position, null: false
      t.timestamps
    end

    # 同一Book内で position は一意
    add_index :book_sections, %i[book_id position], unique: true
  end
end
