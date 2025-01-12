class CreateSchedule < ActiveRecord::Migration[8.0]
  def change
    create_table :schedules do |t|
      t.references :device,        foreign_key: true

      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.boolean :interruptible, default: false, null: false
      t.string :plugins, default: "", null: false
      t.integer :update_frequency, null: true

      t.timestamps
    end
  end
end
