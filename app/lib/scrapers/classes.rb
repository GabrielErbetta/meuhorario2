module Scrapers
  # Scraper for DisciplineClass, DisciplineClassOffer, CourseClassOffer, Schedule
  #   Professor and ProfessorSchedule models
  class Classes
    BASE_URI = 'https://supac.ufba.br'.freeze
    DAYS = %w[CMB SEG TER QUA QUI SEX SAB DOM].freeze

    attr_reader :threads, :queue

    # Initializes the object with the thread count and queue
    def initialize(threads: 1)
      @threads = threads
      @queue = Queue.new
    end

    # Scrapes the schedule guide hubs and enqueues the guides found for scraping
    # Returns count of discipline_class objects after scraping
    def scrape
      agent = Mechanize.new
      hub = agent.get "#{BASE_URI}/guia-matricula-graduacao"

      current_semester = semester_from_hub(hub)

      guides = guide_uris_from_hub(hub)
      guides.each do |guide|
        @queue.push([guide, current_semester])
      end

      runner = ConcurrentRunner.new(queue: @queue, threads:)
      runner.run self, :scrape_classes

      DisciplineClass.count
    end

    private

    # Gets the current semester from the hub page to validate the guides
    def semester_from_hub(hub)
      title = hub.at('h1.title.gutter').text
      title.scan(/\d/).join
    end

    # Scrapes a guide hub and returns the uri of the course guides found
    def guide_uris_from_hub(hub)
      areas = hub.search('#conteudo').css('li')
      guide_links = []

      areas.each do |area_item|
        href = area_item.at_css('a').attr('href')
        href = "#{BASE_URI}/#{href}" unless href.starts_with? 'http'

        agent = Mechanize.new
        area_hub = agent.get href

        guides_container = area_hub.search('div.field-item.even')
        guide_links += guides_container.css('a')
      end

      guide_uris = guide_links.map { |a| URI.join(BASE_URI, a['href']).to_s }
      guide_uris.select { |uri| uri.include? '/sites/supac.ufba.br/files/' }
    end

    # Scrapes a course guide, storing the informations
    # Creates disciplines if they are fuond in the guides but not in the database
    # Stores discipline_class, discipline_class_offer, course_class_offer, schedule, professor and
    #   professor_schedule
    def scrape_classes(guide_uri, current_semester)
      guide = fetch_guide(guide_uri)

      guide_semester = semester_from_guide(guide)
      return if guide_semester != current_semester

      courses = courses_from_uri(guide_uri)
      latest_curriculum = courses.map(&:curriculum).max

      previous_discipline       = nil
      previous_discipline_class = nil
      previous_schedule         = nil

      class_rows = class_rows_from_guide(guide)

      class_rows.each do |row|
        columns = row.css('td')
        next if columns.blank? || columns.text.blank?

        discipline   = discipline_from_row(columns, latest_curriculum)
        discipline ||= previous_discipline

        discipline_class = class_from_row(columns, discipline)
        if discipline_class
          vacancies = vacancies_from_row(columns)
          store_offers(courses, discipline_class, vacancies)
        else
          discipline_class = previous_discipline_class
        end

        schedule_info = schedule_info_from_row(columns, previous_schedule)
        schedule   = store_schedule(discipline_class, schedule_info) if schedule_info
        schedule ||= previous_schedule

        professor = professor_from_row(columns)
        store_professor_schedule(professor, schedule)

        previous_discipline       = discipline
        previous_discipline_class = discipline_class
        previous_schedule         = schedule
      end
    end

    # Fetches the guide html from the uri and parses it with Nokogiri
    # Uses Nokogiri::HTML5 to fix document errors by closing open tags and more
    def fetch_guide(guide_uri)
      guide_html = URI(guide_uri).read
      Nokogiri::HTML5(guide_html, nil, Encoding::ASCII_8BIT)
    end

    # Scrapes the guide for its semester
    def semester_from_guide(guide)
      title = guide.at('p > font > text()').text
      title.scan(/\d/).join
    end

    # Finds the courses from the code in the course guide uri
    def courses_from_uri(uri)
      file_name = uri.split('/').last

      course_code = file_name.chomp('.html').chomp('.htm')
      course_code = course_code.split('_').first
      course_code = '316' if course_code == '301' # For 'Administração' course code divergence

      Course.where('code LIKE ?', "#{course_code}%")
    end

    # Fetches the guide html from the uri and returns the class rows without the header rows
    def class_rows_from_guide(guide)
      rows = guide.search('body').css('table').css('tr')
      return [] if rows.blank?

      rows[7..]
    end

    # Finds the discipline from the current row in the guide
    # Creates a new one if doesn't find any with that code in the database
    # When creating a new discipline, it will use the latest curriculum from the guide courses
    def discipline_from_row(columns, latest_curriculum)
      discipline_text = columns[0].text
      return nil if discipline_text.blank?

      split_text = discipline_text.split(' - ')

      code = split_text[0]
      name = split_text[1..].join(' - ')
      name = Titleizer.discipline_name(name)

      Discipline.create!(code:, name:, curriculum: latest_curriculum)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      Discipline.find_by(code:)
    end

    # Finds the discipline_class from the current row in the guide, creating it if necessary
    def class_from_row(columns, discipline)
      class_number = columns[1].text
      return nil if class_number.blank?

      DisciplineClass.where(discipline:, class_number:).first_or_create
    end

    # Finds the vacancies info from the current row in the guide
    def vacancies_from_row(columns)
      vacancies = columns[2].text
      vacancies.blank? ? nil : vacancies.to_i
    end

    # Stores discipline_class_offer and course_class_offers
    def store_offers(courses, discipline_class, vacancies)
      return if vacancies.blank?

      discipline_class_offer = DisciplineClassOffer.where(discipline_class:)
                                                   .first_or_create(vacancies:)

      courses.each do |course|
        CourseClassOffer.where(course:, discipline_class_offer:).first_or_create
      end
    end

    # Returns a hash with all the infos needed for the schedule model that are found in the
    #   current row of the course guide
    def schedule_info_from_row(columns, previous_schedule)
      day_text = columns[3].text
      hour_text = columns[4].text

      return nil if hour_text.blank?

      day   = DAYS.index day_text
      day ||= previous_schedule.day

      return empty_schedule_info if day == 0

      times = hour_text.split ' às '
      start_hour, start_minute = parse_time(times[0])
      end_hour, end_minute     = parse_time(times[1])

      class_count = parse_class_count(start_hour, start_minute, end_hour, end_minute)
      first_class_slot = parse_first_class_slot(start_hour, start_minute)

      {
        day:,
        start_hour:,
        start_minute:,
        end_hour:,
        end_minute:,
        first_class_slot:,
        class_count:
      }
    end

    # Returns a hash with empty infos for schedules without a set date/time (CMB)
    def empty_schedule_info
      {
        day: 0,
        start_hour: 0,
        start_minute: 0,
        end_hour: 0,
        end_minute: 0,
        first_class_slot: 0,
        class_count: 0
      }
    end

    # Separates a time string into hour and minute
    def parse_time(time)
      time.split(':').map(&:to_i)
    end

    # Parses which class slot of the day a timestamp is from
    def parse_first_class_slot(start_hour, start_minute)
      initial_slot_time = 7 * 60

      current_class = start_hour * 60 + start_minute - initial_slot_time
      current_class -= 30 if start_hour > 12 # Lunch break

      current_class / 55 + 1
    end

    # Parses how many class slots are inside two timestamp
    def parse_class_count(start_hour, start_minute, end_hour, end_minute)
      full_hours = end_hour - start_hour
      partial_minutes = end_minute - start_minute

      total_minutes = full_hours * 60 + partial_minutes

      total_minutes / 55
    end

    # Stores the schedule if not already existent
    def store_schedule(discipline_class, schedule_info)
      Schedule.where(
        discipline_class:,
        day: schedule_info[:day],
        start_hour: schedule_info[:start_hour],
        start_minute: schedule_info[:start_minute]
      ).first_or_create(
        end_hour: schedule_info[:end_hour],
        end_minute: schedule_info[:end_minute],
        first_class_slot: schedule_info[:first_class_slot],
        class_count: schedule_info[:class_count]
      )
    end

    # Finds the professor from the current row in the guide, creating it if necessary
    def professor_from_row(columns)
      name = columns[5].text
      return nil if name.blank?

      Professor.where(name:).first_or_create
    end

    # Stores the professor_schedule if not already existent
    def store_professor_schedule(professor, schedule)
      ProfessorSchedule.where(professor:, schedule:).first_or_create
    end
  end
end
