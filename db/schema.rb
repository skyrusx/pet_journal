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

ActiveRecord::Schema[7.2].define(version: 2026_07_22_111000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "pet_events", force: :cascade do |t|
    t.bigint "pet_id", null: false
    t.integer "event_type", null: false
    t.string "title"
    t.date "event_date", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_id"], name: "index_pet_events_on_pet_id"
  end

  create_table "pet_tag_scans", force: :cascade do |t|
    t.bigint "pet_tag_id", null: false
    t.string "public_token", null: false
    t.text "user_agent"
    t.string "referrer"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "location_note"
    t.datetime "location_shared_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pet_tag_id"], name: "index_pet_tag_scans_on_pet_tag_id"
    t.index ["public_token"], name: "index_pet_tag_scans_on_public_token", unique: true
  end

  create_table "pet_tags", force: :cascade do |t|
    t.bigint "pet_id", null: false
    t.string "public_token", null: false
    t.boolean "enabled", default: true, null: false
    t.text "public_message"
    t.text "behavior_notes"
    t.text "medical_notes"
    t.string "contact_phone"
    t.boolean "show_phone", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "lost_mode_enabled", default: false, null: false
    t.text "lost_message"
    t.string "last_seen_location"
    t.integer "notification_preference", default: 1, null: false
    t.datetime "token_rotated_at"
    t.index ["pet_id"], name: "index_pet_tags_on_pet_id", unique: true
    t.index ["public_token"], name: "index_pet_tags_on_public_token", unique: true
  end

  create_table "pets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "species"
    t.string "breed"
    t.integer "sex"
    t.date "birth_date"
    t.decimal "weight", precision: 6, scale: 2
    t.string "color"
    t.string "chip_number"
    t.string "passport_number"
    t.boolean "neutered"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_pets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "pet_events", "pets"
  add_foreign_key "pet_tag_scans", "pet_tags"
  add_foreign_key "pet_tags", "pets"
  add_foreign_key "pets", "users"
end
