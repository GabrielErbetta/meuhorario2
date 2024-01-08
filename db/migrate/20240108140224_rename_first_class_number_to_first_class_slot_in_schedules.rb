# Renames ´first_class_number´ column to ´first_class_slot´ in ´schedules´ table
class RenameFirstClassNumberToFirstClassSlotInSchedules < ActiveRecord::Migration[7.0]
  def change
    rename_column :schedules, :first_class_number, :first_class_slot
  end
end
