module Scrapers
  # Scraper for Course model
  # This is not multithreaded as it only scrapes one page
  class Courses
    BASE_URI = 'https://alunoweb.ufba.br/SiacWWW/ListaCursosEmentaPublico.do?cdGrauCurso=01'.freeze

    attr_reader :threads, :queue

    # Initializes the object with the thread count and queue
    def initialize(threads: 1)
      @threads = threads
      @queue = Queue.new
    end

    # Scrapes the courses index page and stores the courses listed
    # Returns count of courses after scraping
    def scrape
      agent = Mechanize.new
      hub = agent.get BASE_URI

      courses = hub.search('table a')

      courses.each do |anchor|
        href = anchor.attr('href')
        href_params = parse_course_uri(href)

        Course.where(code: href_params[:code]).first_or_create(
          name: Titleizer.course_name(anchor.text),
          curriculum: href_params[:curriculum]
        )
      end

      Course.count
    end

    private

    # Parses course code and curriculum from the course page link
    def parse_course_uri(href)
      uri = URI.parse href
      params = Rack::Utils.parse_query uri.query

      { code: params['cdCurso'], curriculum: params['nuPerCursoInicial'] }
    end
  end
end
