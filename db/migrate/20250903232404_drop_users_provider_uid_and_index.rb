class DropUsersProviderUidAndIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  INDEX_NAME = "index_users_on_provider_uid".freeze

  def up
    # ① 複合インデックスを先に落とす（存在チェックは name: を使う）
    if index_exists?(:users, nil, name: INDEX_NAME)
      remove_index :users, name: INDEX_NAME, algorithm: :concurrently
    end

    # ② カラムを削除
    remove_column :users, :provider, :string
    remove_column :users, :uid,      :string
  end

  def down
    add_column :users, :provider, :string
    add_column :users, :uid,      :string
    add_index  :users, [ :provider, :uid ], unique: true, name: INDEX_NAME, algorithm: :concurrently
  end
end
