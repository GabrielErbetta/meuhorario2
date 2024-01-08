module Scrapers
  # Scraper for PreRequisite model
  class PreRequisites
    BASE_URI = 'https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do'.freeze

    attr_reader :threads, :queue

    # Initializes the object with the thread count and queue
    def initialize(threads: 1)
      @threads = threads
      @queue = Queue.new
    end

    # Enqueues all the courses for scraping the pre_requisites of the disciplines
    # Returns count of pre requisite objects after scraping
    def scrape
      courses = Course.all

      courses.find_each { |course| @queue.push([course]) }
      Concurrently.run @queue, threads, self, :scrape_course

      PreRequisite.count
    end

    private

    # Opens course page and starts the scraping of the pages for pre requisites
    def scrape_course(course)
      course_uri = "#{BASE_URI}?cdCurso=#{course.code}&nuPerCursoInicial=#{course.curriculum}"

      agent = Mechanize.new
      hub = agent.get course_uri

      hub.links[0..1].each { |link| scrape_pre_requisites(link.click, course) }
    end

    # Scrapes and stores pre requisites from the disciplines table
    def scrape_pre_requisites(page, course)
      table = page.search('table').first
      rows = table.css('tr')[2..]
      return if rows.blank?

      previous_codes = []

      rows.each do |row|
        code, pre_requisite_text = discipline_row_data(row)
        pre_requisite_codes = parse_pre_requisite_text(pre_requisite_text, previous_codes)

        course_discipline = find_course_discipline(course, code)
        store_pre_requisites(course_discipline, pre_requisite_codes)

        previous_codes << code
      end
    end

    # Converts a row of the disciplines table into an array of the infos present
    def discipline_row_data(row)
      cells = row.css('td')

      code = cells[2].text
      pre_requisites = cells[4].text

      [code, pre_requisites]
    end

    # Finds the pre requisites of the discipline in the row and returns them as an array of codes
    def parse_pre_requisite_text(text, previous_codes)
      return [] if text.blank? || text == '--'

      if text.include? 'Todas'
        pre_requisites = previous_codes

        if text.include? 'exceto'
          exceptions = text.split(': ').last.split(', ')
          pre_requisites -= exceptions
        end
      else
        pre_requisites = text.split(', ')
      end

      pre_requisites
    end

    # Finds a course_discipline object by passing the course model and the discipline code
    def find_course_discipline(course, code)
      CourseDiscipline.find_by(
        course:,
        discipline: Discipline.where(code:)
      )
    end

    # Stores the pre requisites of the course discipline
    def store_pre_requisites(course_discipline, pre_requisite_codes)
      course = course_discipline.course

      pre_requisite_codes.each do |code|
        pre_req_cd = find_course_discipline(course, code)
        next if !pre_req_cd || pre_req_cd.semester == course_discipline.semester

        PreRequisite.where(
          pre_discipline: pre_req_cd,
          post_discipline: course_discipline
        ).first_or_create
      end
    end
  end
end
