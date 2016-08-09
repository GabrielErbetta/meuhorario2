class CreateCourseDisciplines < ActiveRecord::Migration[5.0]
  def change
    create_table :course_disciplines do |t|
      t.integer :semester
      t.string :nature, limit: 3
      t.references :course, foreign_key: true
      t.references :discipline, foreign_key: true

      t.timestamps
    end
  end
end
