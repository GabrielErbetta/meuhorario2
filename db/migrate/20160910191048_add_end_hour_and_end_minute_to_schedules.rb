class AddEndHourAndEndMinuteToSchedules < ActiveRecord::Migration[5.0]
  def change
    rename_column :schedules, :hour, :start_hour
    rename_column :schedules, :minute, :start_minute
    add_column :schedules, :end_hour, :integer
    add_column :schedules, :end_minute, :integer
    add_column :schedules, :first_class_number, :integer
    add_column :schedules, :class_count, :integer
  end
end
