class CreateEditorPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :editor_permissions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string  :target_type, null: false
      t.bigint  :target_id,   null: false
      t.integer :role,        null: false, default: 0

      t.timestamps
    end

    add_index :editor_permissions, [ :user_id, :target_type, :target_id ],
              unique: true, name: "index_editor_permissions_on_user_and_target"
    add_index :editor_permissions, [ :target_type, :target_id ]
  end
end
