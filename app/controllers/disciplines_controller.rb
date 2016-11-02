class DisciplinesController < ApplicationController
  layout false, only: [:get_information, :ajax_search]

  def get_information
    @discipline = Discipline.includes(discipline_classes: { schedules: :professors }).find_by_code params[:code]

    if params[:course].present?
      @course = Course.find_by_code params[:course]

      course_discipline = CourseDiscipline.includes([
        pre_requisites:  { pre_discipline:  :discipline },
        post_requisites: { post_discipline: :discipline }
      ]).where(discipline: @discipline, course: @course).first

      if course_discipline
        @pre_requisites = course_discipline.pre_requisites.map { |pre| pre.pre_discipline.discipline }
        @post_requisites = course_discipline.post_requisites.map { |post| post.post_discipline.discipline }
      end
    end

    @discipline_classes = @discipline.discipline_classes.includes(discipline_class_offers: :courses)
    @available_discipline_classes = []
    @course_class_offers = {}

    schedules = {}
    @discipline_classes.each do |dc|
      cco = dc.discipline_class_offers.includes(:courses).where(courses: {:id => @course.id}).first
      if cco
        @available_discipline_classes << dc
        @discipline_classes -= [dc]
        @course_class_offers[dc.id] = cco
      end
      dc.schedules.each do |schedule|
        (schedules[dc.class_number] ||= []) << { day: schedule.day, daytime_number: schedule.daytime_number, class_count: schedule.class_count }
      end
    end
    @schedules = schedules.to_json
  end

  def ajax_search
    @disciplines = Discipline.where 'unaccent(name) ILIKE unaccent(?) or code ILIKE ?', "%#{params[:pattern]}%", "%#{params[:pattern]}%"
  end
end