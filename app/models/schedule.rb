class Schedule < ApplicationRecord
  belongs_to :discipline_class
  has_many :professor_schedules, dependent: :destroy
  has_many :professors, through: :professor_schedules

  def day_friendly
    days = ['CMB', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM']
    return days[self.day]
  end

  def start_hour_friendly
    return "#{"%02d" % self.start_hour}:#{"%02d" % self.start_minute}"
  end

  def end_hour_friendly
    return "#{"%02d" % self.end_hour}:#{"%02d" % self.end_minute}"
  end

  def daytime_number
    n = self.start_hour * 60
    n -= 30 if self.start_hour > 12
    n -= 7 * 60
    n += self.start_minute
    n /= 55

    return n + 1
  end
end
