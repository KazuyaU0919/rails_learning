class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      # 表示名（アプリ側のバリデーションも併用）
      t.string  :name,       null: false, limit: 30

      # 正規化名：NFKC→strip→squeeze_space→downcase（アプリ側で生成）
      t.string  :name_norm,  null: false, limit: 60

      # URL 用 slug（ローマ字化＋a-z0-9-）
      t.string  :slug,       null: false, limit: 80

      # "#RRGGBB"（未指定はアプリ側で自動色）
      t.string  :color,      limit: 7

      # counter_cache
      t.integer :taggings_count, null: false, default: 0

      t.timestamps
    end

    add_index :tags, :name_norm, unique: true
    add_index :tags, :slug,      unique: true

    # PostgreSQL: 色の形式チェック（NULL は許可）
    add_check_constraint :tags,
                         "color IS NULL OR color ~ '^#[0-9A-Fa-f]{6}$'",
                         name: "tags_color_hex"
  end
end
