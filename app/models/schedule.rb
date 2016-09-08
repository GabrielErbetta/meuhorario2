class Schedule < ApplicationRecord
  belongs_to :discipline_class
  has_many :professor_schedules, dependent: :destroy
  has_many :professors, through: :professor_schedules

  def day_friendly
    days = ['CMB', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM']
    return days[self.day]
  end
end
