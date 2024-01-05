module Scrapers
  # Scraper for additional Discipline information
  # Currently only scrapes hours but can be extended to scrape other infos in the page
  class DisciplineInfos
    BASE_URI = 'https://alunoweb.ufba.br/SiacWWW/ExibirEmentaPublico.do'.freeze

    attr_reader :threads, :queue

    # Initializes the object with the thread count and queue
    def initialize(threads: 1)
      @threads = threads
      @queue = Queue.new
    end

    # Enqueues all the disciplines for scraping
    # Returns count of disciplines with hours after scraping
    def scrape
      disciplines = Discipline.where(hours: nil)

      disciplines.find_each { |discipline| @queue.push([discipline]) }
      Concurrently.run @queue, threads, self, :scrape_discipline_infos

      Discipline.where.not(hours: nil).count
    end

    private

    # Opens discipline infos page and stores the hours of the discipline
    def scrape_discipline_infos(discipline)
      discipline_infos_uri =
        "#{BASE_URI}?cdDisciplina=#{discipline.code}&nuPerInicial=#{discipline.curriculum}"

      agent = Mechanize.new
      info_page = agent.get discipline_infos_uri

      body = info_page.body
      hours = body.match(/Carga Hor.ria - Total: (\d+) horas/)&.captures&.first

      discipline.update(hours:)
    end
  end
end
