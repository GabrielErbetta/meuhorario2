# Adds a unique index for code column in disciplines table
# This index prevents duplicate disciplines when scraping disciplines with multiple threads
# First removes previous non-unique index
class AddCodeUniqueIndexToDisciplines < ActiveRecord::Migration[7.0]
  def change
    remove_index :disciplines, :code
    add_index :disciplines, :code, unique: true
  end
end
