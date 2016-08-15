class AddCurriculumToCourses < ActiveRecord::Migration[5.0]
  def change
    add_column :courses, :curriculum, :string
  end
end
