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

ActiveRecord::Schema[8.0].define(version: 2025_01_11_144630) do
  create_table "active_schedules", force: :cascade do |t|
    t.integer "devices_id"
    t.integer "schedules_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["devices_id"], name: "index_active_schedules_on_devices_id"
    t.index ["schedules_id"], name: "index_active_schedules_on_schedules_id"
  end

  create_table "devices", force: :cascade do |t|
    t.string "name"
    t.string "mac_address"
    t.string "api_key"
    t.string "friendly_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schedule_events", force: :cascade do |t|
    t.integer "schedules_id"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.boolean "interruptible", default: false, null: false
    t.string "plugins", default: "", null: false
    t.integer "update_frequency"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["schedules_id"], name: "index_schedule_events_on_schedules_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.string "name", null: false
    t.integer "schedule_id"
    t.string "default_plugin", default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "active_schedules", "devices", column: "devices_id"
  add_foreign_key "active_schedules", "schedules", column: "schedules_id"
  add_foreign_key "schedule_events", "schedules", column: "schedules_id"
end
