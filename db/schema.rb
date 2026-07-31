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

ActiveRecord::Schema[7.2].define(version: 2026_07_31_031427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cranes", force: :cascade do |t|
    t.bigint "inspection_request_id", null: false
    t.string "crane_type", null: false
    t.string "lm_number", null: false
    t.string "rope_diameter_mm", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inspection_request_id", "position"], name: "index_cranes_on_inspection_request_id_and_position"
    t.index ["inspection_request_id"], name: "index_cranes_on_inspection_request_id"
  end

  create_table "fsps", force: :cascade do |t|
    t.string "full_name", null: false
    t.string "contact_number", null: false
    t.string "email", null: false
    t.integer "sequence_number", null: false
    t.string "fsp_number", null: false
    t.date "date_joined", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "country_code", default: "+65", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["color"], name: "index_fsps_on_color", unique: true
    t.index ["email"], name: "index_fsps_on_email", unique: true
    t.index ["fsp_number"], name: "index_fsps_on_fsp_number", unique: true
    t.index ["reset_password_token"], name: "index_fsps_on_reset_password_token", unique: true
    t.index ["sequence_number"], name: "index_fsps_on_sequence_number", unique: true
  end

  create_table "inspection_requests", force: :cascade do |t|
    t.string "company_name", null: false
    t.string "requestor_name", null: false
    t.string "contact_number", null: false
    t.string "email"
    t.string "site_name", null: false
    t.string "status", default: "pending", null: false
    t.string "share_token"
    t.date "scheduled_on"
    t.time "scheduled_time"
    t.string "assigned_inspector"
    t.text "notes"
    t.datetime "accepted_at"
    t.datetime "scheduled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "rejected_at"
    t.bigint "fsp_id"
    t.string "country_code", default: "+65", null: false
    t.index ["fsp_id"], name: "index_inspection_requests_on_fsp_id"
    t.index ["share_token"], name: "index_inspection_requests_on_share_token", unique: true
    t.index ["status"], name: "index_inspection_requests_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "country_code", default: "+65", null: false
    t.string "contact_number", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cranes", "inspection_requests"
  add_foreign_key "inspection_requests", "fsps"
end
