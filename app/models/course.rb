class Course < ApplicationRecord
  has_many :course_disciplines
  has_many :disciplines, through: :course_disciplines
  has_many :discipline_class_offers
end
