class ProfessorSchedule < ApplicationRecord
  belongs_to :schedule
  belongs_to :professor
end
