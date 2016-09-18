namespace :crawler do

  desc 'Crawl courses codes, names and curriculums'
  task :courses => :environment do
    puts '-----------------------------------------------------------------------'
    puts '-> Starting courses crawling...'

    require 'rubygems'
    require 'mechanize'

    agent = Mechanize.new
    page = agent.get 'https://alunoweb.ufba.br/SiacWWW/ListaCursosEmentaPublico.do?cdGrauCurso=01'

    courseAnchors = page.search('a')

    courseAnchors.each do |a|
      url = a.attribute('href').value

      codeIndex = url.index('cdCurso') + 8
      code = url[codeIndex..codeIndex + 5]

      curriculumIndex = url.index('nuPerCursoInicial') + 18
      curriculum = url[curriculumIndex..curriculumIndex + 4]

      course = Course.find_by_code 'code'
      unless course
        course = Course.new
        course.code = code
        course.name = a.text
        course.area = code[0].to_i
        course.curriculum = curriculum
        course.save
      end
    end
    puts '-> Finished courses crawling'
    puts '-----------------------------------------------------------------------'
  end


  desc 'Crawl the disciplines of every known course'
  task :disciplines => :environment do
    puts '-----------------------------------------------------------------------'
    puts '-> Starting disciplines crawling...'

    require 'rubygems'
    require 'mechanize'

    Course.all.order(:code).each do |course|
      puts "    Crawling #{course.name}"

      agent = Mechanize.new
      hub = agent.get "https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do?cdCurso=#{course.code}&nuPerCursoInicial=#{course.curriculum}"

      for i in 0..1
        page = hub.links[i].click

        table = page.search('table')[0]
        rows = table.css('tr')[2..-1]

        semester = nil
        rows.each do |row|
          columns = row.css('td')

          semester = columns[0].css('b').text.to_i unless columns[0].css('b').text.blank?
          nature = columns[1].text
          code = columns[2].text
          name = columns[3].css('a').text.strip
          name = columns[3].text.strip if name == ""

          discipline = Discipline.find_by_code code

          unless discipline
            discipline = Discipline.new
            discipline.code = code
            discipline.name = name
            discipline.save
          end

          course_discipline = CourseDiscipline.where(course_id: course.id, discipline_id: discipline.id)
          if course_discipline.blank?
            course_discipline = CourseDiscipline.new
            course_discipline.semester = semester
            course_discipline.nature = nature
            course_discipline.discipline = discipline
            course_discipline.course = course
            course_discipline.save
          end
        end
      end
    end
    puts '-> Finished disciplines crawling'
    puts '-----------------------------------------------------------------------'
  end


  desc 'Crawl the disciplines of every known course'
  task :pre_requisites => :environment do
    puts '-----------------------------------------------------------------------'
    puts '-> Starting pre-requisites crawling...'

    require 'rubygems'
    require 'mechanize'

    Course.all.order(:code).each do |course|
      puts "    Crawling #{course.name}"

      agent = Mechanize.new
      hub = agent.get "https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do?cdCurso=#{course.code}&nuPerCursoInicial=#{course.curriculum}"

      disciplines = []

      for i in 0..1
        page = hub.links[i].click

        table = page.search('table')[0]
        rows = table.css('tr')[2..-1]

        rows.each do |row|
          columns = row.css('td')

          code = columns[2].text
          disciplines << code
          discipline = Discipline.find_by_code code
          course_discipline = CourseDiscipline.where(course_id: course.id, discipline_id: discipline.id).first

          full_requisites = columns[4].text

          unless full_requisites == '--'
            if full_requisites.include? 'Todas'
              requisites = disciplines - [code]

              if full_requisites.include? 'exceto'
                non_requisites = full_requisites.split(': ').last.split(', ')
                requisites -= non_requisites
              end
            else
              requisites = full_requisites.split(', ')
            end

            requisites.each do |requisite|
              pre_discipline = Discipline.find_by_code requisite
              pre_cd = CourseDiscipline.where(course: course, discipline: pre_discipline).first

              if pre_cd.blank?
                puts "      Código não encontrado: #{requisite} | Disciplina: #{discipline.name} | Curso: #{course.name}"
              elsif pre_cd.semester.nil? or pre_cd.semester != course_discipline.semester
                pr = PreRequisite.new
                pr.pre_discipline = pre_cd
                pr.post_discipline = course_discipline
                pr.save
              end
            end
          end
        end
      end
    end
    puts '-> Finished pre-requisites crawling'
    puts '-----------------------------------------------------------------------'
  end


  desc 'Crawl computer science classes page'
  task :cs_disciplines => :environment do
    course = Course.find_by_code '112'
    unless course
      course = Course.new
      course.code = '112'
      course.name = 'Ciência da Computação'
      course.save
    end

    require 'rubygems'
    require 'mechanize'

    agent = Mechanize.new
    hub = agent.get 'https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do?cdCurso=112140&nuPerCursoInicial=20132'

    for i in 0..1
      page = hub.links[i].click

      table = page.search('table')[0]
      rows = table.css('tr')[2..-1]

      semester = nil
      rows.each do |row|
        columns = row.css('td')

        semester = columns[0].css('b').text.to_i unless columns[0].css('b').text.blank?
        nature = columns[1].text
        code = columns[2].text
        name = columns[3].css('a').text.strip
        requisites = columns[4].text
        requisites = requisites == '--' ? [] : requisites.split(', ')

        discipline = Discipline.find_by_code code

        unless discipline
          discipline = Discipline.new
          discipline.code = code
          discipline.name = name
          discipline.save
        end

        course_discipline = CourseDiscipline.where(course_id: course.id, discipline_id: discipline.id)
        if course_discipline.blank?
          course_discipline = CourseDiscipline.new
          course_discipline.semester = semester
          course_discipline.nature = nature
          course_discipline.discipline = discipline
          course_discipline.course = course
          course_discipline.save

          requisites.each do |requisite|
            pre_discipline = Discipline.find_by_code requisite
            pre_cd = CourseDiscipline.where(course: course, discipline: pre_discipline).first

            if (pre_cd.blank?)
              puts "Código não encontrado: #{requisite} | Disciplina: #{discipline.name} | Curso: #{course.name}"
            else
              pr = PreRequisite.new
              pr.pre_discipline = pre_cd
              pr.post_discipline = course_discipline
              pr.save
            end
          end
        end
      end
    end
  end


  desc 'Crawl computer science classes page'
  task :cs_classes => :environment do
    course_code = '112'
    courses = Course.where "code LIKE ?", "#{course_code}%"

    require 'nokogumbo'

    days = ['CMB', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM']

    page = Nokogiri::HTML5.get 'https://twiki.ufba.br/twiki/pub/SUPAC/GradGuiaAreaI1/112.html'

    body = page.search('body')
    course_name = body.css('font')[1].text.split(': ')[1]
    table = body.css('table')
    rows = table.css('tr')

    discipline = nil
    class_n = nil
    d_class = nil
    vacancies = nil
    day = nil
    day_number = nil
    time = nil
    professor = nil
    schedules = []

    rows[7..-1].each do |row|
      columns = row.css('td')

      unless columns.blank?
        discipline_text = columns[0].children[0].text
        if discipline_text != ''
          d_parts = discipline_text.split(' - ')
          d_code = d_parts[0]

          discipline = Discipline.find_by_code d_code

          if discipline.nil?
            discipline = Discipline.new
            discipline.code = d_code
            discipline.name = d_parts[1..-1].join(' - ')
            discipline.save
          end
        end

        if columns[1].children[0].text != ''
          class_n = columns[1].children[0].text
          vacancies = columns[2].children[0].text

          d_class = DisciplineClass.where(discipline: discipline, class_number: class_n).first
          unless d_class
            d_class = DisciplineClass.new
            d_class.discipline = discipline
            d_class.class_number = class_n
            d_class.save
          end

          courses.each do |course|
            dc_offer = course.discipline_class_offers.where(discipline_class: d_class).first
            unless dc_offer
              dc_offer = DisciplineClassOffer.new
              dc_offer.discipline_class = d_class
              dc_offer.vacancies = vacancies
              dc_offer.save

              cc_offer = CourseClassOffer.new
              cc_offer.course = course
              cc_offer.discipline_class_offer = dc_offer
              cc_offer.save
            end
          end
        end

        if columns[3].children[0].text != ''
          day = columns[3].children[0].text
          day_number = days.index day
        end

        n_classes = 0
        if columns[4].children[0].text != ''
          schedules = []

          times = columns[4].children[0].text.split ' às '
          start_time = times[0].split ':'
          start_hour = start_time[0].to_i
          start_minute = start_time[1].to_i

          if day_number == 0
            n_classes = 1
          else
            end_time = times[1].split ':'
            end_hour = end_time[0].to_i
            end_minute = end_time[1].to_i

            n_classes = ((end_hour - start_hour) * 60 + (end_minute - start_minute)) / 55
          end
        end

        n_classes.times do |i|
          schedule = Schedule.new
          schedule.day = day_number
          schedule.hour = start_hour + ((i * 55 + start_minute) / 60)
          schedule.minute = (start_minute + i * 55) % 60
          schedule.discipline_class = d_class
          schedule.save
          schedules << schedule
        end

        professor_name = columns[5].children[0].text.strip unless columns[5].children[0].text == ''
        professor = Professor.find_by_name professor_name
        unless professor
          professor = Professor.new
          professor.name = professor_name
          professor.save
        end

        schedules.each do |schedule|
          professor_schedule = ProfessorSchedule.new
          professor_schedule.schedule = schedule
          professor_schedule.professor = professor
          professor_schedule.save
        end
      end
    end
  end


  desc 'Crawl all courses class pages'
  task :classes => :environment do
    require 'nokogumbo'
    require 'rubygems'
    require 'mechanize'

    puts '-----------------------------------------------------------------------'
    puts '-> Starting classes crawling...'

    days = ['CMB', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM']

    agent = Mechanize.new
    hub = agent.get "http://www.twiki.ufba.br/twiki/bin/view/SUPAC/MatriculaGraduacaoColegiado1"
    area_hubs = hub.search('a.twikiLink').select{ |a| a['href'].include? 'GradGuia' }.map{ |a| agent.get a['href'] }

    area_hubs.each do |area_hub|
      guides_table = area_hub.search('table#table1')
      guide_urls = guides_table.css('a').map { |a| a['href'] }
      guides = guide_urls.map { |url| Nokogiri::HTML5.get url }

      guides.each_with_index do |page, index|
        page.encoding = 'windows-1252'

        course_hash = {}
        course_code = guide_urls[index].split('/')[-1]
        course_code.slice! '.html'

        Course.where('code LIKE ?', "#{course_code}%").each { |c| (course_hash[course_code] ||= []) << c }

        course_hash.each do |course_code, courses|
          puts "-> Crawling #{course_code}"
          body = page.search('body')
          course_name = body.css('font')[1].text.split(': ')[1]
          table = body.css('table')
          rows = table.css('tr')

          discipline = nil
          d_class = nil
          day_number = nil
          schedule = nil

          rows[7..-1].each do |row|
            columns = row.css('td')

            unless columns.blank?
              discipline_text = columns[0].children[0].text
              if discipline_text != ''
                d_parts = discipline_text.split(' - ')
                d_code = d_parts[0]

                discipline = Discipline.find_by_code d_code

                if discipline.nil?
                  discipline = Discipline.new
                  discipline.code = d_code
                  discipline.name = d_parts[1..-1].join(' - ')
                  discipline.save
                end
              end

              if columns[1].children[0].text != ''
                class_n = columns[1].children[0].text
                vacancies = columns[2].children[0].text

                d_class = DisciplineClass.where(discipline: discipline, class_number: class_n).first
                unless d_class
                  d_class = DisciplineClass.new
                  d_class.discipline = discipline
                  d_class.class_number = class_n
                  d_class.save
                end

                courses.each do |course|
                  dc_offer = course.discipline_class_offers.where(discipline_class: d_class).first
                  unless dc_offer
                    dc_offer = DisciplineClassOffer.new
                    dc_offer.discipline_class = d_class
                    dc_offer.vacancies = vacancies
                    dc_offer.save

                    cc_offer = CourseClassOffer.new
                    cc_offer.course = course
                    cc_offer.discipline_class_offer = dc_offer
                    cc_offer.save
                  end
                end
              end

              if columns[3].children[0].text != ''
                day = columns[3].children[0].text
                day_number = days.index day
              end

              if columns[4].children[0].text != ''
                unless day_number == 0
                  times = columns[4].children[0].text.split ' às '
                  start_time = times[0].split ':'
                  start_hour = start_time[0].to_i
                  start_minute = start_time[1].to_i

                  end_time = times[1].split ':'
                  end_hour = end_time[0].to_i
                  end_minute = end_time[1].to_i

                  n_classes = ((end_hour - start_hour) * 60 + (end_minute - start_minute)) / 55

                  first_class_number = (start_hour * 60) - (7 * 60) + start_minute
                  first_class_number -= 30 if start_hour > 12
                  first_class_number /= 55
                  first_class_number += 1
                end

                schedule = Schedule.where(discipline_class: d_class, day: day_number, start_hour: start_hour, start_minute: start_minute).first
                unless schedule
                  schedule = Schedule.new
                  schedule.day = day_number
                  if day_number != 0
                    schedule.start_hour = start_hour
                    schedule.start_minute = start_minute
                    schedule.end_hour = end_hour
                    schedule.end_minute = end_minute
                    schedule.first_class_number = first_class_number
                    schedule.class_count = n_classes
                  else
                    schedule.start_hour = 0
                    schedule.start_minute = 0
                    schedule.end_hour = 0
                    schedule.end_minute = 0
                    schedule.first_class_number = 0
                    schedule.class_count = 0
                  end
                  schedule.discipline_class = d_class
                  schedule.save
                end
              end

              professor_name = columns[5].children[0].text.strip unless columns[5].children[0].text == ''
              professor = Professor.find_by_name professor_name
              unless professor
                professor = Professor.new
                professor.name = professor_name
                professor.save
              end

              professor_schedule = ProfessorSchedule.where(schedule: schedule, professor: professor).first
              unless professor_schedule
                professor_schedule = ProfessorSchedule.new
                professor_schedule.schedule = schedule
                professor_schedule.professor = professor
                professor_schedule.save
              end
            end
          end
        end
      end
    end
    puts '-> Finished classes crawling'
    puts '-----------------------------------------------------------------------'
  end
end
