class CreatePreCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :pre_codes do |t|
      t.references :user, null: false, foreign_key: true       # FK + index
      t.string  :title,      null: false
      t.text    :description
      t.text    :body,       null: false
      t.integer :like_count, null: false, default: 0
      t.integer :use_count,  null: false, default: 0
      t.timestamps
    end

    # よく使う順に追加 index
    add_index :pre_codes, [ :user_id, :created_at ]
    add_index :pre_codes, :title
  end
end
