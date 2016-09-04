class Professor < ApplicationRecord
  has_many :schedule_professors
  has_many :schedules, through: :schedule_professors
end
