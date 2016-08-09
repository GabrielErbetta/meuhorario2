class CourseDiscipline < ApplicationRecord
  belongs_to :course
  belongs_to :discipline
end
