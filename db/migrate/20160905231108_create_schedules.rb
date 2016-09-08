class CreateSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :schedules do |t|
      t.integer :day
      t.integer :hour
      t.integer :minute
      t.references :discipline_class, foreign_key: true
    end
  end
end
