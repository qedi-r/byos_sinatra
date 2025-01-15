class CreateSchedule < ActiveRecord::Migration[8.0]
  def change
    create_table :schedule_events do |t|
      t.references :schedules,        foreign_key: true

      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.boolean :interruptible, default: false, null: false
      t.string :plugins, default: "", null: false
      t.integer :update_frequency, null: true

      t.timestamps null: :false
    end

    create_table :schedules do |t|
      t.string :name, null: false
      t.integer :schedule_id

      t.string :default_plugin, default: ""

      t.timestamps null: :false
    end
     
    create_table :active_schedules do |t|
      t.references :devices,        foreign_key: true
      t.references :schedules,        foreign_key: true

      t.timestamps null: :false
    end
  end
end
