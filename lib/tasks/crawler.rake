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
        next if rows.blank?
        rows.each do |row|
          columns = row.css('td')

          semester = columns[0].text.to_i unless columns[0].text.blank?
          nature = columns[1].text
          code = columns[2].text
          name = columns[3].css('a').text.strip
          name = columns[3].text.strip if name == ""

          curriculum = nil
          discipline_link = columns[3].css('a')
          if discipline_link.size == 1 && discipline_link.first.attr('href') =~ /nuPerInicial=(\d+)/
            curriculum = $1
          end

          discipline = Discipline.find_by_code code

          unless discipline
            discipline = Discipline.new
            discipline.code = code
            discipline.name = name
            discipline.curriculum = curriculum
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

  desc 'Crawl discipline info'
  task :discipline_infos => :environment do
    puts '-----------------------------------------------------------------------'
    puts '-> Starting disciplines info crawling...'

    require 'rubygems'
    require 'mechanize'

    Discipline.where(load: nil).order(:name).each do |discipline|
      puts "    Crawling #{discipline.code} - #{discipline.name}"

      agent = Mechanize.new
      hub = agent.get "https://alunoweb.ufba.br/SiacWWW/ExibirEmentaPublico.do?cdDisciplina=#{discipline.code}&nuPerInicial=#{discipline.curriculum}"

      body = hub.body.force_encoding("iso-8859-1").encode('utf-8')
      if body =~ /Carga Hor.ria - Total: (\d+) horas/
        discipline.load = $1.to_i
        discipline.save
      end
    end
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

        next if rows.blank?
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


  desc 'Crawl all courses class pages'
  task :classes => :environment do
    require 'rubygems'
    require 'mechanize'

    puts '-----------------------------------------------------------------------'
    puts '-> Starting classes crawling...'

    days = ['CMB', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM']

    agent = Mechanize.new
    agent.open_timeout = 300
    agent.read_timeout = 300

    hub = agent.get 'https://supac.ufba.br/guia-matricula-graduacao'
    area_hubs = hub.search('#conteudo').css('a').map{ |a| agent.get a['href'] }

    area_hubs.each do |area_hub|
      guides_list = area_hub.search('div.field-item.even')
      guide_urls = guides_list.css('a').map{ |a| URI.join(area_hub.uri, a['href']).to_s }.delete_if{ |a| a.include? 'www2.supac.ufba.br' }
      guides = guide_urls.map { |url| Nokogiri::HTML5.get(url, {open_timeout: 300, read_timeout: 300}) }

      guides.each_with_index do |page, index|
        page.encoding = 'windows-1252'

        course_hash = {}
        course_code = guide_urls[index].split('/')[-1]
        course_code.slice! '.html'
        course_code.slice! '.htm'
        course_code = course_code.split('_')[0]

        course_code = '316' if course_code == '301'

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

          next if rows.blank?
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
                if day_number == 0
                  start_hour = 0
                  start_minute = 0
                  end_hour = 0
                  end_minute = 0
                  first_class_number = 0
                  class_count = 0
                else
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
                  schedule.start_hour = start_hour
                  schedule.start_minute = start_minute
                  schedule.end_hour = end_hour
                  schedule.end_minute = end_minute
                  schedule.first_class_number = first_class_number
                  schedule.class_count = n_classes
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

  desc 'Downcase and capitalize discipline names and upcase roman numbers'
  task :titleize => :environment do
    puts '-----------------------------------------------------------------------'
    uncapitalized = [
      'de', 'a', 'o', 'que', 'e', 'do', 'da', 'em', 'um', 'para', 'é', 'com', 'não', 'uma', 'os', 'no',
      'se', 'na', 'por', 'mais', 'as', 'dos', 'como', 'mas', 'foi', 'ao', 'ele', 'das', 'tem', 'à', 'seu', 'sua', 'ou',
      'ser', 'quando', 'muito', 'há', 'nos', 'já', 'está', 'eu', 'também', 'só', 'pelo', 'pela', 'até', 'isso', 'ela',
      'entre', 'era', 'depois', 'sem', 'mesmo', 'aos', 'ter', 'seus', 'quem', 'nas', 'me', 'esse', 'eles', 'estão',
      'você', 'tinha', 'foram', 'essa', 'num', 'nem', 'suas', 'meu', 'às', 'minha', 'têm', 'numa', 'pelos', 'elas',
      'havia', 'seja', 'qual', 'será', 'nós', 'tenho', 'lhe', 'deles', 'essas', 'esses', 'pelas', 'este', 'fosse',
      'dele', 'tu', 'te', 'vocês', 'vos', 'lhes', 'meus', 'minhas', 'teu', 'tua', 'teus', 'tuas', 'nosso', 'nossa',
      'nossos', 'nossas', 'dela', 'delas', 'esta', 'estes', 'estas', 'aquele', 'aquela', 'aqueles', 'aquelas', 'isto',
      'aquilo', 'estou', 'está', 'estamos', 'estão', 'estive', 'esteve', 'estivemos', 'estiveram', 'estava',
      'estávamos', 'estavam', 'estivera', 'estivéramos', 'esteja', 'estejamos', 'estejam', 'estivesse', 'estivéssemos',
      'estivessem', 'estiver', 'estivermos', 'estiverem', 'hei', 'há', 'havemos', 'hão', 'houve', 'houvemos',
      'houveram', 'houvera', 'houvéramos', 'haja', 'hajamos', 'hajam', 'houvesse', 'houvéssemos', 'houvessem',
      'houver', 'houvermos', 'houverem', 'houverei', 'houverá', 'houveremos', 'houverão', 'houveria', 'houveríamos',
      'houveriam', 'sou', 'somos', 'são', 'era', 'éramos', 'eram', 'fui', 'foi', 'fomos', 'foram', 'fora', 'fôramos',
      'seja', 'sejamos', 'sejam', 'fosse', 'fôssemos', 'fossem', 'for', 'formos', 'forem', 'serei', 'será', 'seremos',
      'serão', 'seria', 'seríamos', 'seriam', 'tenho', 'tem', 'temos', 'tém', 'tinha', 'tínhamos', 'tinham', 'tive',
      'teve', 'tivemos', 'tiveram', 'tivera', 'tivéramos', 'tenha', 'tenhamos', 'tenham', 'tivesse', 'tivéssemos',
      'tivessem', 'tiver', 'tivermos', 'tiverem', 'terei', 'terá', 'teremos', 'terão', 'teria', 'teríamos', 'teriam'
    ]

    puts '-> Starting titleizing courses...'
    courses = Course.all
    courses.each do |course|
      name = course.name.mb_chars.downcase.to_s

      name.gsub!(/[\p{L}]+/) { |match| uncapitalized.include?(match) ? match : match.mb_chars.capitalize.to_s }
      name.gsub!(/(\b)(i|ii|iii|iv|v|vi|vii|viii|ix|x|b|c|d|f|g|h)(\b)|((\b)(a|e)$)/i) { |match| match.upcase }

      course.name = name
      course.save
    end
    puts '-> Finished'


    puts '-> Starting titleizing disciplines...'
    disciplines = Discipline.all
    disciplines.each do |discipline|
      name = discipline.name.mb_chars.downcase.to_s

      name.gsub!(/[\p{L}]+/) { |match| uncapitalized.include?(match) ? match : match.mb_chars.capitalize.to_s }
      name.gsub!(/(\b)(i|ii|iii|iv|v|vi|vii|viii|ix|x|b|c|d|f|g|h)(\b)|((\b)(a|e)$)/i) { |match| match.upcase }
      name.gsub!(/[\;\:\.\,\_\&\*\?\/\\]\S/) { |match| match[0] + ' ' + match[1] }

      discipline.name = name
      discipline.save
    end
    puts '-> Finished'

    puts '-----------------------------------------------------------------------'
  end

  desc 'Downcase and capitalize discipline names and upcase roman numbers'
  task :areas => :environment do
    require 'rubygems'
    require 'mechanize'

    puts '-----------------------------------------------------------------------'
    puts '-> Starting areas crawling...'
    agent = Mechanize.new
    hub = agent.get 'https://supac.ufba.br/guia-matricula-graduacao'
    areas = hub.search('#conteudo').css('a')

    areas.each do |a|
      area_text = a.children[0].text.split('-').map { |string| string.gsub(/\A[[:space:]]+|[[:space:]]+\z/, '') }

      if area_text[0].include? 'Bacharelados Interdisciplinares'
        name = 'BI'
        description = area_text[0]
      else
        name = area_text[0]
        description = area_text[1]
      end

      area = Area.where(name: name).first
      unless area
        area = Area.new
        area.name = name
        area.description = description
        area.save
      end

      area_hub = agent.get a['href']
      guides_list = area_hub.search('div.field-item.even')
      guide_urls = guides_list.css('a').map { |a| a['href'] }

      guide_urls.each do |guide_url|
        course_code = guide_url.split('/')[-1]
        course_code.slice! '.html'
        course_code.slice! '.htm'
        course_code = course_code.split('_')[0]

        course_code = '316' if course_code == '301'

        Course.where('code LIKE ?', "#{course_code}%").each do |course|
          course.area = area
          course.save
        end
      end
    end

    puts '-> Finished'
    puts '-----------------------------------------------------------------------'
  end
end
