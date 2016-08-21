class CreatePreRequisite < ActiveRecord::Migration[5.0]
  def change
    create_table :pre_requisites do |t|
      t.references :course_discipline, foreign_key: true, index: true
      t.references :discipline, foreign_key: true, index: true

      t.timestamps
    end
  end
end
