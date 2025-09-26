class AddPositionToBooks < ActiveRecord::Migration[8.0]
  def up
    # まず nullable で追加（既存行があるため）
    add_column :books, :position, :integer

    # created_at 昇順で 1,2,3... を採番（PostgreSQL想定。MySQLならROW_NUMBERの書き方だけ変える）
    execute <<~SQL.squish
      WITH ordered AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY created_at ASC, id ASC) AS seq
        FROM books
      )
      UPDATE books b SET position = o.seq
      FROM ordered o
      WHERE o.id = b.id;
    SQL

    # 必須化
    change_column_null :books, :position, false

    # 受入基準の「重複はエラー」を満たすなら unique を付ける（不要なら unique: false に変更可）
    add_index :books, :position, unique: true
  end

  def down
    remove_index :books, :position if index_exists?(:books, :position)
    remove_column :books, :position
  end
end
