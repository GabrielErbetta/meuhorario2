class DisciplineClass < ApplicationRecord
  belongs_to :discipline
  has_many :discipline_class_offers
  has_many :schedules
end
