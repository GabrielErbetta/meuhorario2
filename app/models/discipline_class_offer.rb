class DisciplineClassOffer < ApplicationRecord
  has_many :course_class_offers, dependent: :destroy
  has_many :courses, through: :course_class_offers
  belongs_to :discipline_class
end
