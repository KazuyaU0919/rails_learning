class SwapUsersEmailUniqueIndexToGlobal < ActiveRecord::Migration[8.0]
  # 部分インデックスを壊さず切り替えるため、トランザクション外で CONCURRENTLY を使う
  disable_ddl_transaction!

  NEW_INDEX = "index_users_on_lower_email_unique".freeze
  OLD_INDEX = "index_users_on_email_unique_when_provider_is_null".freeze

  def up
    # ① 新: lower(email) に対するグローバル一意インデックスを追加
    add_index :users, "lower(email)", unique: true,
              name: NEW_INDEX, algorithm: :concurrently

    # ② 旧: provider IS NULL の部分インデックスを削除
    remove_index :users, name: OLD_INDEX, algorithm: :concurrently
  end

  def down
    # 旧インデックスを復元（ロールバック用）
    add_index :users, "lower((email))", unique: true,
              where: "(provider IS NULL)",
              name: OLD_INDEX, algorithm: :concurrently

    remove_index :users, name: NEW_INDEX, algorithm: :concurrently
  end
end
