class CoursesController < ApplicationController

  def show
    @course = Course.find_by_code params[:code]

    unless @course.nil?
      @semesters = []
      pre = {}
      post = {}

      @course.course_disciplines.each do |d|
        if @semesters[d.semester] == nil
          @semesters[d.semester] = [d.discipline]
        else
          @semesters[d.semester] << d.discipline
        end

        pre_requisites = PreRequisite.where(course_discipline: d)
        pre_requisites.each do |p|
          if pre[d.discipline.code] == nil
            pre[d.discipline.code] = [p.discipline.code]
          else
            pre[d.discipline.code] << p.discipline.code
          end
        end

        post_requisites = PreRequisite.where(discipline: d.discipline)
        post_requisites.each do |p|
          if post[d.discipline.code] == nil
            post[d.discipline.code] = [p.course_discipline.discipline.code]
          else
            post[d.discipline.code] << p.course_discipline.discipline.code
          end
        end

        require 'json'
        @pre  = pre.to_json
        @post = post.to_json
      end
    end
  end

end