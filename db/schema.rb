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

ActiveRecord::Schema[7.2].define(version: 2024_11_20_172746) do
  create_table "domains", force: :cascade do |t|
    t.string "fqdn", null: false
    t.text "users"
    t.text "groups"
    t.boolean "group_delegation", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fqdn"], name: "index_domains_on_fqdn", unique: true
  end

  create_table "kv_metadata", force: :cascade do |t|
    t.string "path", null: false
    t.string "owner", null: false
    t.string "read_groups"
    t.string "write_groups"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_kv_metadata_on_path", unique: true
  end

  create_table "sql_audit_logs", force: :cascade do |t|
    t.string "request_id", null: false
    t.string "action", null: false
    t.string "result", null: false
    t.string "error"
    t.string "subject", null: false
    t.string "cert_common_name"
    t.string "kv_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject", "created_at"], name: "index_sql_audit_logs_on_subject_and_created_at"
  end
end
