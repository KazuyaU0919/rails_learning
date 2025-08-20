class CreateUsedCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :used_codes do |t|
      t.references :user,     null: false, foreign_key: true, index: true
      t.references :pre_code, null: false, foreign_key: true, index: true
      t.datetime   :used_at,  null: false
      t.timestamps
    end

    add_index :used_codes, [ :user_id, :pre_code_id ], unique: true
  end
end
