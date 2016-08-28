class CreatePreRequisite < ActiveRecord::Migration[5.0]
  def change
    create_table :pre_requisites do |t|
      t.references :pre_discipline, references: :course_discipline, index: true
      t.references :post_discipline, references: :course_discipline, index: true

      t.timestamps
    end

    add_foreign_key :pre_requisites, :course_discipline, column: :pre_discipline_id
    add_foreign_key :pre_requisites, :course_discipline, column: :post_discipline_id
  end
end
