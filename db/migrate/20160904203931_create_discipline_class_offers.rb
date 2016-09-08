class CreateDisciplineClassOffers < ActiveRecord::Migration[5.0]
  def change
    create_table :discipline_class_offers do |t|
      t.references :discipline_class, foreign_key: true
      t.integer :vacancies
    end
  end
end
