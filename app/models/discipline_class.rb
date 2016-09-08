class DisciplineClass < ApplicationRecord
  belongs_to :discipline
  has_many :discipline_class_offers, dependent: :destroy
  has_many :schedules, dependent: :destroy
end
