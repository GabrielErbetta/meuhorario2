namespace :scraper do
  desc 'Runs all scraper tasks in sequence'
  task all: :environment do
    Rake::Task['scraper:courses'].invoke
    Rake::Task['scraper:areas'].invoke
    Rake::Task['scraper:disciplines'].invoke
    Rake::Task['scraper:pre_requisites'].invoke
    Rake::Task['scraper:classes'].invoke
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

  desc 'Scrape classes and schedule from the SUPAC schedule guides'
  task classes: :environment do
    processor_cores = `grep -c processor /proc/cpuinfo`.to_i
    threads = [4, processor_cores].min

    puts '-> Starting classes scraping...'

    classes_scraper = Scrapers::Classes.new(threads:)
    discipline_classes = classes_scraper.scrape

    puts "    #{discipline_classes} classes found"
    puts '-> Finished'
  end
end
