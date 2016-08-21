class CourseDiscipline < ApplicationRecord
  belongs_to :course
  belongs_to :discipline
  has_many :pre_requisites, :dependent => :destroy
end
