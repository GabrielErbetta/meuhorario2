class AddLoadToDisciplines < ActiveRecord::Migration[5.0]
  def change
    add_column :disciplines, :load, :integer
  end
end
