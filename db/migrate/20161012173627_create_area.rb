class CreateArea < ActiveRecord::Migration[5.0]
  def change
    create_table :areas do |t|
      t.string :name
      t.string :description
    end

    remove_column :courses, :area, :integer
    add_reference :courses, :area, index: true
  end
end
