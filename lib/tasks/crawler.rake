namespace :crawler do

  desc 'Crawl courses codes, names and curriculums'
  task :courses => :environment do
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
        course.curriculum = curriculum
        course.save
      end
    end
  end


  desc 'Crawl the disciplines of every known course'
  task :disciplines => :environment do
    Course.all.each do |course|
      require 'rubygems'
      require 'mechanize'

      agent = Mechanize.new
      page = agent.get "https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do?cdCurso=#{course.code}&nuPerCursoInicial=#{course.curriculum}"
      page = page.links[0].click

      table = page.search('table')[0]
      rows = table.css('tr')[2..-1]

      semester = 1
      rows.each do |row|
        columns = row.css('td')

        semester = columns[0].css('b').text.to_i unless columns[0].css('b').text.blank?
        nature = columns[1].text
        code = columns[2].text
        name = columns[3].css('a').text.strip
        name = columns[3].text.strip if name == ""
        requisites = columns[4].text
        requisites = requisites == '--' ? [] : requisites.split(', ')

        discipline = Discipline.find_by_code code

        unless discipline
          discipline = Discipline.new
          discipline.code = code
          discipline.name = name
          discipline.requisites = requisites.join '|'
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
            pre_req_discipline = Discipline.find_by_code requisite

            if (pre_req_discipline.blank?)
              puts "Código não encontrado: #{requisite} | Disciplina: #{discipline.name} | Curso: #{course.name}"
            else
              pr = PreRequisite.new
              pr.course_discipline = course_discipline
              pr.discipline = pre_req_discipline
              pr.save
            end
          end
        end
      end
    end
  end


  desc 'Crawl computer science classes page'
  task :cs_classes => :environment do
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
    page = agent.get 'https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do?cdCurso=112140&nuPerCursoInicial=20132'
    page = page.links[0].click

    table = page.search('table')[0]
    rows = table.css('tr')[2..-1]

    semester = 1
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
        discipline.requisites = requisites.join '|'
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
          puts "#{requisite}"
          pr = PreRequisite.new
          pr.course_discipline = course_discipline
          pr.discipline = Discipline.find_by_code requisite
          pr.save
        end
      end
    end
  end
end