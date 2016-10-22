class DisciplinesController < ApplicationController
  layout false, only: [:get_information]

  def get_information
    @discipline = Discipline.find_by_code params[:code]
    @course = Course.find_by_code params[:course]

    if @discipline and @course
      @course_discipline = CourseDiscipline.where(discipline: @discipline, course: @course).first

      if @course_discipline
        @pre_requisites = @course_discipline.pre_requisites
        @post_requisites = @course_discipline.post_requisites

        @discipline_classes = @discipline.discipline_classes
      end
    end
  end

  def ajax_search
    @disciplines = Discipline.where 'name ILIKE ? or code ILIKE ?', "%#{params[:pattern]}%", "%#{params[:pattern]}%"
  end
end