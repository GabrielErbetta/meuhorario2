class Professor < ApplicationRecord
  has_many :professor_schedules, dependent: :destroy
  has_many :schedules, through: :professor_schedules
end
