class Discipline < ApplicationRecord
  has_many :course_disciplines, dependent: :destroy
  has_many :courses, through: :course_disciplines
  has_many :discipline_classes, dependent: :destroy

  validates :code, presence: true, uniqueness: true
end
