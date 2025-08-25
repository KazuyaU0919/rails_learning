class CreateSolidCacheEntries < ActiveRecord::Migration[8.0]
  def change
    # Solid Cache は主キーを持たないので id: false
    create_table :solid_cache_entries, id: false do |t|
      t.binary   :key,       null: false, limit: 1024
      t.binary   :value,     null: false, limit: 536_870_912
      t.datetime :created_at,            null: false
      t.integer  :key_hash,  null: false, limit: 8
      t.integer  :byte_size, null: false, limit: 4
    end

    add_index :solid_cache_entries, :byte_size
    add_index :solid_cache_entries, [ :key_hash, :byte_size ],
              name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    add_index :solid_cache_entries, :key_hash, unique: true
  end
end
