class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :pre_code, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end

    # 複合ユニーク（同じ組み合わせを防ぐ）
    add_index :bookmarks, [ :user_id, :pre_code_id ], unique: true,
              name: "index_bookmarks_on_user_id_and_pre_code_id"
  end
end
