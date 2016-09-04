class Schedule < ApplicationRecord
  belongs_to :class
  has_many :schedule_professors
  has_many :professors, through: :schedule_professors
end
