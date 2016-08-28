class CreateCourses < ActiveRecord::Migration[5.0]
  def change
    create_table :courses do |t|
      t.string  :name
      t.string  :code, index: true
      t.integer :area

      t.timestamps
    end
  end
end
