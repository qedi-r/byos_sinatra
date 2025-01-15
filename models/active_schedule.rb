class ActiveSchedules < ActiveRecord::Base
  belongs_to :devices
  belongs_to :schedules
end