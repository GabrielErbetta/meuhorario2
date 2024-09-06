module Scrapers
  # Scraper for Discipline and CourseDiscipline models
  class Disciplines
    BASE_URI = 'https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do'.freeze

    attr_reader :threads, :queue

    # Initializes the object with the thread count and queue
    def initialize(threads: 1)
      @threads = threads
      @queue = Queue.new
    end

    # Enqueues all the courses for scraping
    # Returns count of disciplines after scraping
    def scrape
      courses = Course.all

      courses.find_each { |course| @queue.push([course]) }

      runner = ConcurrentRunner.new(queue: @queue, threads:)
      runner.run self, :scrape_course

      Discipline.count
    end

    private

    # Opens course page and starts the scraping of the pages for required and optative disciplines
    def scrape_course(course)
      course_uri = "#{BASE_URI}?cdCurso=#{course.code}&nuPerCursoInicial=#{course.curriculum}"

      agent = Mechanize.new
      hub = agent.get course_uri

      hub.links[0..1].each { |link| scrape_disciplines(link.click, course) }
    end

    # Scrapes and stores disciplines from required or optative disciplines page
    def scrape_disciplines(page, course)
      table = page.search('table').first
      rows = table.css('tr')[2..]
      return if rows.blank?

      current_semester = nil

      rows.each do |row|
        semester, nature, code, name, curriculum = discipline_row_data(row)

        semester   ||= current_semester if nature == 'OB'
        curriculum ||= course.curriculum
        current_semester = semester

        discipline = store_discipline(code, name, curriculum)
        store_course_discipline(course, discipline, semester, nature)
      end
    end

    # Converts a row of the disciplines table into an array of the infos present
    def discipline_row_data(row)
      cells = row.css('td')

      semester = cells[0].text.presence&.to_i
      nature = cells[1].text&.upcase
      code = cells[2].text
      name = Titleizer.discipline_name(cells[3].text)
      curriculum = curriculum_from_cell(cells[3])

      [semester, nature, code, name, curriculum]
    end

    # Finds the curriculum semester of the discipline in the discipline name cell
    def curriculum_from_cell(cell)
      link = cell.at_css('a')&.attr('href')
      return if link.blank?

      link.match(/nuPerInicial=(\d+)/)&.captures&.first
    end

    # Stores the discipline preventing duplicates
    def store_discipline(code, name, curriculum)
      Discipline.create!(code:, name:, curriculum:)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      Discipline.find_by(code:)
    end

    # Stores the course discipline
    def store_course_discipline(course, discipline, semester, nature)
      CourseDiscipline.where(course:, discipline:)
                      .first_or_create(semester:, nature:)
    end
  end
end
