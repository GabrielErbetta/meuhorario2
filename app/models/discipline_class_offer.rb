class DisciplineClassOffer < ApplicationRecord
  belongs_to :course
  belongs_to :discipline_class
end
