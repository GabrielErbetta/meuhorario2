class CreateCourseClassOffers < ActiveRecord::Migration[5.0]
  def change
    create_table :course_class_offers do |t|
      t.references :course, foreign_key: true
      t.references :discipline_class_offer, foreign_key: true
    end
  end
end
