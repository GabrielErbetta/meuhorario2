# Renames `load` column to `hours` in `disciplines` table
class RenameLoadToHoursInDisciplines < ActiveRecord::Migration[7.0]
  def change
    rename_column :disciplines, :load, :hours
  end
end
