class CreateDisciplines < ActiveRecord::Migration[5.0]
  def change
    create_table :disciplines do |t|
      t.string :code, index: true
      t.string :name

      t.timestamps
    end
  end
end
