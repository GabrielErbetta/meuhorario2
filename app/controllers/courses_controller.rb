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
      ]
    ).find_by_code params[:code]

    cds = @course.course_disciplines

    unless @course.nil?
      @semesters = []
      pre = {}
      post = {}

      cds.reject{ |cd| cd.nature != 'OB' }.each do |cd|
        (@semesters[cd.semester] ||= []) << cd.discipline

        pre_requisites = cd.pre_requisites
        pre_requisites.each do |p|
          (pre[cd.discipline.code] ||= []) << p.pre_discipline.discipline.code
        end

        post_requisites = cd.post_requisites
        post_requisites.each do |p|
          (post[cd.discipline.code] ||= []) << p.post_discipline.discipline.code
        end
      end

      @pre  = pre.to_json
      @post = post.to_json
    end

    @ops = cds.reject{ |cd| cd.nature == 'OB' }

    @dcos = DisciplineClassOffer.includes(discipline_class: [{schedules: :professors}, :discipline]).where(id: @course.discipline_class_offer_ids)

    unless @dcos.blank?
      schedules = {}

      @dcos.each do |dco|
        key = "#{dco.discipline_class.discipline.code}-#{dco.discipline_class.class_number}"
        dco.discipline_class.schedules.each do |schedule|
          (schedules[key] ||= []) << schedule.day * 100 + schedule.daytime_number unless schedule.day == 0
        end
      end
    end

    @schedules = schedules.to_json
  end

end