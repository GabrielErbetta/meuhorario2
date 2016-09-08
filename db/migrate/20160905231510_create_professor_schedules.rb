class CreateProfessorSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :professor_schedules do |t|
      t.references :schedule, foreign_key: true
      t.references :professor, foreign_key: true
    end
  end
end
