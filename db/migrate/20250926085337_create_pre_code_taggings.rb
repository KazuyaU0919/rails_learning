class CreatePreCodeTaggings < ActiveRecord::Migration[8.0]
  def change
    create_table :pre_code_taggings do |t|
      t.references :pre_code, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag,      null: false, foreign_key: true

      t.timestamps
    end

    add_index :pre_code_taggings, [ :pre_code_id, :tag_id ],
              unique: true,
              name: "index_pre_code_taggings_on_pre_code_id_and_tag_id"
  end
end
