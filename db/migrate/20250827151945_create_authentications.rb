class CreateAuthentications < ActiveRecord::Migration[8.0]
  def change
    create_table :authentications do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade } # ユーザー削除で紐づきも削除
      t.string :provider, null: false
      t.string :uid,      null: false
      t.timestamps
    end

    # グローバル一意：同じ (provider, uid) の組み合わせは世界に1つ
    add_index :authentications, [ :provider, :uid ], unique: true

    # 同一ユーザーで同じ provider を2本持てないように（誤登録防止）
    add_index :authentications, [ :user_id, :provider ], unique: true
  end
end
