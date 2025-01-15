class Schedule < ActiveRecord::Base
  has_many :schedule_events 
  has_many :events, through: :schedule_events
  has_many :active_schedules
  has_many :devices, through: :active_schedules
end