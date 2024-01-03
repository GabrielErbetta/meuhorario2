module Scrapers
  # Scraper for Area model
  class Areas
    BASE_URI = 'https://supac.ufba.br'.freeze

    attr_reader :threads, :queue

    # Initializes the object with the thread count and queue
    def initialize(threads: 1)
      @threads = threads
      @queue = Queue.new
    end

    # Scrapes and stores the area, then updates the association of the courses of the area
    # Returns count of areas after scraping
    def scrape
      agent = Mechanize.new
      hub = agent.get "#{BASE_URI}/guia-matricula-graduacao"

      areas = hub.search('#conteudo').css('li')

      areas.each do |area_item|
        name, description = area_item.text.split('-')
        area = store_area(name, description)

        href = area_item.at_css('a').attr('href')
        @queue.push([area, href])
      end

      Concurrently.run @queue, threads, self, :update_courses
      update_orphan_courses

      Area.count
    end

    private

    # Receives the name and description of area, strips spaces and stores it as an Area object
    #   Returns an Area object
    def store_area(name, description)
      name = Titleizer.super_strip(name)
      description = Titleizer.super_strip(description)

      if name == 'Bacharelados Interdisciplinares'
        description = name
        name = 'BI'
      end

      Area.where(name:).first_or_create(name:, description:)
    end

    # Scrapes the courses of the area in href and updates the Area association of the related Courses
    def update_courses(area, href)
      href = "#{BASE_URI}/#{href}" unless href.starts_with?('http')

      agent = Mechanize.new
      area_hub = agent.get href

      codes = course_codes_from_area_page(area_hub)
      codes.each do |code|
        Course.where('code LIKE ?', "#{code}%").update_all(area_id: area.id)
      end
    end

    # Scrapes the course codes from the area courses page
    def course_codes_from_area_page(page)
      strongs = page.search('div.field-item.even strong').to_a
      strongs.select! { |strong| strong.text.match?(/\d+ -/) }
      strongs.map     { |strong| strong.text.remove(/\D/) }
    end

    # Manually updates orphan courses that aren't present in any of the area courses pages
    def update_orphan_courses
      update_area_i_orphan_courses
      update_area_iii_orphan_courses
      update_area_v_orphan_courses
    end

    # Updates orphan courses that should be linked to Área I
    def update_area_i_orphan_courses
      area_i = Area.find_by(name: 'Área I')
      area_i_codes = [
        '127120' # Matemática
      ]
      Course.where(code: area_i_codes).update(area: area_i)
    end

    # Updates orphan courses that should be linked to Área III
    def update_area_iii_orphan_courses
      area_iii = Area.find_by(name: 'Área III')
      area_iii_codes = [
        '882140', # Administração Pública
        '537140', # Biblioteconomia
        '886140', # Gestão do Turismo e Desenvolvimento Sustentável
        '875120', # Pedagogia
        '846140'  # Segurança Pública
      ]
      Course.where(code: area_iii_codes).update(area: area_iii)
    end

    # Updates orphan courses that should be linked to Área V
    def update_area_v_orphan_courses
      area_v = Area.find_by(name: 'Área V')
      area_v_codes = [
        '510140', # Artes Cênicas - Interpretação Teatral
        '511140', # Teatro
        '521120', # Teatro
        '848120', # Dança
        '884120'  # Música
      ]
      Course.where(code: area_v_codes).update(area: area_v)
    end
  end
end
