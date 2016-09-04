class CreateDisciplineClasses < ActiveRecord::Migration[5.0]
  def change
    create_table :discipline_classes do |t|
      t.references :discipline, foreign_key: true
      t.string :class_number
    end
  end
end
