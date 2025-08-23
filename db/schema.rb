# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_23_133942) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "book_sections", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.string "heading", null: false
    t.text "content", null: false
    t.boolean "is_free", default: false, null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "position"], name: "index_book_sections_on_book_id_and_position", unique: true
    t.index ["book_id"], name: "index_book_sections_on_book_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "book_sections_count", default: 0, null: false
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "pre_code_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pre_code_id"], name: "index_likes_on_pre_code_id"
    t.index ["user_id", "pre_code_id"], name: "index_likes_on_user_id_and_pre_code_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "pre_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.text "body", null: false
    t.integer "like_count", default: 0, null: false
    t.integer "use_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_pre_codes_on_title"
    t.index ["user_id", "created_at"], name: "index_pre_codes_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_pre_codes_on_user_id"
  end

  create_table "used_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "pre_code_id", null: false
    t.datetime "used_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pre_code_id"], name: "index_used_codes_on_pre_code_id"
    t.index ["user_id", "pre_code_id"], name: "index_used_codes_on_user_id_and_pre_code_id", unique: true
    t.index ["user_id"], name: "index_used_codes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "email", limit: 255
    t.string "password_digest"
    t.string "provider"
    t.string "uid"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_email_unique_when_provider_is_null", unique: true, where: "(provider IS NULL)"
    t.index ["provider", "uid"], name: "index_users_on_provider_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token_unique", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "book_sections", "books"
  add_foreign_key "likes", "pre_codes"
  add_foreign_key "likes", "users"
  add_foreign_key "pre_codes", "users"
  add_foreign_key "used_codes", "pre_codes"
  add_foreign_key "used_codes", "users"
end
