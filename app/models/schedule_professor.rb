class ScheduleProfessor < ApplicationRecord
  belongs_to :schedule
  belongs_to :professor
end
