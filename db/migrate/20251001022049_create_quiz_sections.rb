class CreateQuizSections < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_sections do |t|
      t.references :quiz, null: false, foreign_key: true
      t.string  :heading,  null: false
      t.boolean :is_free,  null: false, default: false
      t.integer :position, null: false
      t.timestamps
    end
    add_index :quiz_sections, [ :quiz_id, :position ]
  end
end
