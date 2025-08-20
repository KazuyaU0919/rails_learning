class CreateLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :likes do |t|
      t.references :user,     null: false, foreign_key: true, index: true
      t.references :pre_code, null: false, foreign_key: true, index: true
      t.timestamps
    end

    add_index :likes, [ :user_id, :pre_code_id ], unique: true
  end
end
