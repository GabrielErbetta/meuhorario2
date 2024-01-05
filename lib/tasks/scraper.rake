namespace :scraper do
  desc 'Runs all scraper tasks in sequence'
  task all: :environment do
    Rake::Task['scraper:courses'].invoke
    Rake::Task['scraper:areas'].invoke
    Rake::Task['scraper:disciplines'].invoke
    Rake::Task['scraper:pre_requisites'].invoke
    Rake::Task['scraper:discipline_infos'].invoke
  end

  desc 'Scrapes courses info from a public courses list'
  task courses: :environment do
    puts '-> Starting courses scraping...'

    courses_scraper = Scrapers::Courses.new
    courses = courses_scraper.scrape

    puts "    #{courses} courses found"
    puts '-> Finished'
  end

  desc 'Scrapes course areas from SUPAC'
  task areas: :environment do
    processor_cores = `grep -c processor /proc/cpuinfo`.to_i
    threads = [4, processor_cores].min

    puts '-> Starting areas scraping...'

    areas_scraper = Scrapers::Areas.new(threads:)
    areas = areas_scraper.scrape

    orphan_courses = Course.where(area: nil)

    puts "    #{areas} areas found"
    puts "    #{orphan_courses.size} orphan courses remain"
    puts '-> Finished'
  end

  desc 'Scrape the disciplines of every known course'
  task disciplines: :environment do
    processor_cores = `grep -c processor /proc/cpuinfo`.to_i
    threads = [4, processor_cores].min

    puts '-> Starting disciplines scraping...'

    disciplines_scraper = Scrapers::Disciplines.new(threads:)
    disciplines = disciplines_scraper.scrape

    puts "    #{disciplines} disciplines found"
    puts '-> Finished'
  end

  desc 'Crawl the disciplines of every known course'
  task pre_requisites: :environment do
    processor_cores = `grep -c processor /proc/cpuinfo`.to_i
    threads = [4, processor_cores].min

    puts '-> Starting pre requisites scraping...'

    pre_requisites_scraper = Scrapers::PreRequisites.new(threads:)
    pre_requisites = pre_requisites_scraper.scrape

    puts "    #{pre_requisites} pre requisite links between disciplines"
    puts '-> Finished'
  end

  desc 'Scrape additional infos for every known discipline'
  task discipline_infos: :environment do
    processor_cores = `grep -c processor /proc/cpuinfo`.to_i
    threads = [4, processor_cores].min

    puts '-> Starting discipline infos scraping...'

    discipline_infos_scraper = Scrapers::DisciplineInfos.new(threads:)
    updated_disciplines = discipline_infos_scraper.scrape

    puts "    #{updated_disciplines} disciplines with hours"
    puts '-> Finished'
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
end
