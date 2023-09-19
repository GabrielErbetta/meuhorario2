module Scrapers
  # Scraper for Area model
  class Areas
    BASE_URI = 'https://supac.ufba.br/'.freeze

    attr_reader :threads, :queue

    # Initializes the object with the thread count and queue
    def initialize(threads: 1)
      @threads = threads
      @queue = Queue.new
    end

    # Scrapes and stores the area, then updates the association of the courses of the area
    def scrape
      agent = Mechanize.new
      hub = agent.get "#{BASE_URI}/guia-matricula-graduacao"

      areas = hub.search('#conteudo').css('li')

      areas.each do |area_item|
        name, description = area_item.text.split('-')
        area = store_area(name, description)

        href = area_item.at_css('a')['href']
        @queue.push([area, href])
      end

      Concurrently.run @queue, threads, self, :update_courses
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

      Area.first_or_create(name:, description:)
    end

    # Scrapes the courses of the area in href and updates the Area association of the related Courses
    def update_courses(area, href)
      href = "#{BASE_URI}/#{href}" unless href.starts_with?('http')

      agent = Mechanize.new
      area_hub = agent.get href

      anchors = area_hub.search('div.field-item.even div a')
      codes = anchors.map { |anchor| anchor.parent.element_children.first.text }

      codes.each do |code|
        code = code.remove(/\D/)
        Course.where('code LIKE ?', "#{code}%").update_all(area_id: area.id)
      end
    end
  end
end
