class CoursesController < ApplicationController

  def show
    @course = Course.includes(
      course_disciplines: [
        { pre_requisites: [
            { pre_discipline: :discipline },
            { post_discipline: :discipline }
          ],
          post_requisites: [
            { pre_discipline: :discipline },
            { post_discipline: :discipline }
          ]
        },
        :discipline
      ],
      discipline_class_offers: {
        discipline_class: :discipline
      }
    ).find_by_code params[:code]

    cds = @course.course_disciplines

    unless @course.nil?
      @semesters = []
      pre = {}
      post = {}

      cds.reject{ |cd| cd.nature != 'OB' }.each do |cd|
        (@semesters[cd.semester] ||= []) << cd.discipline

        pre_requisites = cd.pre_requisites.reject{ |pre| pre.pre_discipline.nature != 'OB' }
        pre_requisites.each do |p|
          (pre[cd.discipline.code] ||= []) << p.pre_discipline.discipline.code
        end

        post_requisites = cd.post_requisites.reject{ |post| post.post_discipline.nature != 'OB' }
        post_requisites.each do |p|
          (post[cd.discipline.code] ||= []) << p.post_discipline.discipline.code
        end
      end

      @pre  = pre.to_json
      @post = post.to_json
    end

    @ops     = cds.reject{ |cd| cd.nature == 'OB' }.map{ |cd| cd.discipline }
    @offered = @course.discipline_class_offers.map{ |dco| dco.discipline_class.discipline }.uniq
  end
end
