class CourseDiscipline < ApplicationRecord
  belongs_to :course
  belongs_to :discipline
  has_many :pre_requisites, foreign_key: :post_discipline_id, class_name: "PreRequisite"
  has_many :post_requisites, foreign_key: :pre_discipline_id, class_name: "PreRequisite"
end
