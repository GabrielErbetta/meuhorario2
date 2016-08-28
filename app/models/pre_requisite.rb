class PreRequisite < ApplicationRecord
  belongs_to :pre_discipline, class_name: 'CourseDiscipline', foreign_key: 'pre_discipline_id'
  belongs_to :post_discipline, class_name: 'CourseDiscipline', foreign_key: 'post_discipline_id'
end