# db/migrate/xxxxxxxxxxxxxx_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # プロフィール系
      t.string :name,  null: false, limit: 50

      # 通常ログイン用（メール + パスワード）
      t.string :email, limit: 255
      t.string :password_digest

      # 外部ログイン用
      t.string :provider
      t.string :uid

      # パスワード再設定
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      t.boolean :admin, null: false, default: false

      t.timestamps
    end

    # ▼ DBレベルの一意制約
    # 1) 外部ログイン：provider+uid の組み合わせは一意
    add_index :users, [ :provider, :uid ], unique: true, name: "index_users_on_provider_uid"

    # 2) 通常ログイン：email一意（外部ログイン行は対象外）
    add_index :users,
      "lower(email)",
      unique: true,
      name: "index_users_on_email_unique_when_provider_is_null",
      where: "provider IS NULL"

    # 3) リセットトークンはユニーク（任意だが安全のため推奨）
    add_index :users, :reset_password_token, unique: true, name: "index_users_on_reset_password_token_unique"
  end
end
