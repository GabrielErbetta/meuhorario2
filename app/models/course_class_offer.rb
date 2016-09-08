class CourseClassOffer < ApplicationRecord
  belongs_to :discipline_class_offer
  belongs_to :course
end
