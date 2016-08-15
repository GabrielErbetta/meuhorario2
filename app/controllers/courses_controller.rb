class CoursesController < ApplicationController

  def show
    @course = Course.find_by_code params[:code]

    unless @course.nil?
      @semesters = []
      @course.course_disciplines.each do |d|
        if @semesters[d.semester] == nil
          @semesters[d.semester] = [d.discipline]
        else
          @semesters[d.semester] << d.discipline
        end
      end
    end
  end

end