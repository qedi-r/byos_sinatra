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
  create_table "devices", force: :cascade do |t|
    t.string "name"
    t.string "mac_address"
    t.string "api_key"
    t.string "friendly_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schedules", force: :cascade do |t|
    t.integer "device_id"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.boolean "interruptible", default: false, null: false
    t.string "plugins", default: "", null: false
    t.integer "update_frequency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_schedules_on_device_id"
  end

  add_foreign_key "schedules", "devices"
end
