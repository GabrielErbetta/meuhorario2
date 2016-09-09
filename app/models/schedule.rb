class Schedule < ApplicationRecord
  belongs_to :discipline_class
  has_many :professor_schedules, dependent: :destroy
  has_many :professors, through: :professor_schedules

  def day_friendly
    days = ['CMB', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM']
    return days[self.day]
  end

  def daytime_number
    n = self.hour * 60
    n -= 30 if self.hour > 12
    n -= 7 * 60
    n += self.minute
    n /= 55

    return n + 1
  end
end
