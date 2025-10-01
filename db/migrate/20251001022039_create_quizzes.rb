class CreateQuizzes < ActiveRecord::Migration[8.0]
  def change
    create_table :quizzes do |t|
      t.string  :title,       null: false
      t.text    :description, null: false
      t.integer :position,    null: false
      t.timestamps
    end
    add_index :quizzes, :position
  end
end
