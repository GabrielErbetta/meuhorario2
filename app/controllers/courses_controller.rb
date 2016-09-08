class CoursesController < ApplicationController

  def show
    @course = Course.find_by_code params[:code]

    unless @course.nil?
      @semesters = []
      pre = {}
      post = {}

      @course.course_disciplines.where(nature: 'OB').each do |cd|
        if @semesters[cd.semester] == nil
          @semesters[cd.semester] = [cd.discipline]
        else
          @semesters[cd.semester] << cd.discipline
        end

        pre_requisites = cd.pre_requisites
        pre_requisites.each do |p|
          if pre[cd.discipline.code] == nil
            pre[cd.discipline.code] = [p.pre_discipline.discipline.code]
          else
            pre[cd.discipline.code] << p.pre_discipline.discipline.code
          end
        end

        post_requisites = cd.post_requisites
        post_requisites.each do |p|
          if post[cd.discipline.code] == nil
            post[cd.discipline.code] = [p.post_discipline.discipline.code]
          else
            post[cd.discipline.code] << p.post_discipline.discipline.code
          end
        end

        require 'json'
        @pre  = pre.to_json
        @post = post.to_json
      end
    end

    @ops = @course.course_disciplines.where.not(nature: 'OB')


    @dcos = @course.discipline_class_offers
  end

end