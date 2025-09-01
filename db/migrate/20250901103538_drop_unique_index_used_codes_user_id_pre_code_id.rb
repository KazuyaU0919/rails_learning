class DropUniqueIndexUsedCodesUserIdPreCodeId < ActiveRecord::Migration[8.0]
  def change
    # 1) 既存ユニークインデックスを削除（存在すれば）
    remove_index :used_codes,
                 name: "index_used_codes_on_user_id_and_pre_code_id",
                 if_exists: true

    # 2) 非ユニークで作り直し（同名でOK／存在していれば作らない）
    add_index :used_codes, [ :user_id, :pre_code_id ],
              name: "index_used_codes_on_user_id_and_pre_code_id",
              unique: false,
              if_not_exists: true

    # 3) 参照最適化用の補助インデックス（任意）
    add_index :used_codes, [ :pre_code_id, :created_at ],
              name: "index_used_codes_on_pre_code_id_and_created_at",
              if_not_exists: true
  end
end
