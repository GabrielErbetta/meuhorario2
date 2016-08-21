class PreRequisite < ApplicationRecord
  belongs_to :course_discipline
  belongs_to :discipline
end