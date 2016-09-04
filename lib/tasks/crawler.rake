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

    Course.all.order(:name).each do |course|
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

    Course.all.order(:name).each do |course|
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

              if (pre_cd.blank?)
                puts "      Código não encontrado: #{requisite} | Disciplina: #{discipline.name} | Curso: #{course.name}"
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
    course = Course.find_by_code '112'

    require 'nokogumbo'

    page = Nokogiri::HTML5.get 'https://twiki.ufba.br/twiki/pub/SUPAC/GradGuiaAreaI1/112.html'

    body = page.search('body')
    course_name = body.css('font')[1].text.split(': ')[1]
    table = body.css('table')
    rows = table.css('tr')

    discipline = nil
    class_n = nil
    vacancies = nil
    day = nil
    time = nil
    professor = nil

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

          class_n = columns[1].children[0].text unless columns[1].children[0].text == ''
          puts class_n

          vacancies = columns[2].children[0].text unless columns[2].children[0].text == ' '
          puts vacancies

          d_class = DisciplineClass.where(discipline: discipline, class_number: class_n).first
          unless d_class
            d_class = DisciplineClass.new
            d_class.discipline = discipline
            d_class.class_number = class_n
            d_class.save
          end

          dc_offer = DisciplineClassOffer.where(course: course, discipline_class: d_class).first
          puts "--------------#{dc_offer.inspect}"
          unless dc_offer
            dc_offer = DisciplineClassOffer.new
            dc_offer.course = course
            dc_offer.discipline_class = d_class
            dc_offer.vacancies = vacancies
            dc_offer.save
            puts "--------------#{dc_offer.inspect}"
          end
        end

        day = columns[3].children[0].text unless columns[3].children[0].text == ''
        puts day

        time = columns[4].children[0].text unless columns[4].children[0].text == ''
        puts time

        professor = columns[5].children[0].text unless columns[5].children[0].text == ''
        puts professor
      end
    end
  end
end
