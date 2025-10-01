class CreateQuizQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_questions do |t|
      t.references :quiz,         null: false, foreign_key: true
      t.references :quiz_section, null: false, foreign_key: true
      t.text    :question,        null: false
      t.string  :choice1,         null: false
      t.string  :choice2,         null: false
      t.string  :choice3,         null: false
      t.string  :choice4,         null: false
      t.integer :correct_choice,  null: false
      t.text    :explanation,     null: false
      t.integer :position,        null: false
      t.timestamps
    end
    add_index :quiz_questions, [ :quiz_section_id, :position ]
  end
end
