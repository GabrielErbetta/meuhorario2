namespace :scraper do
  desc 'Runs all scraper tasks in sequence'
  task :all, [:threads] => [:environment] do |_, args|
    threads = args[:threads]&.to_i || default_thread_count

    Rake::Task['scraper:courses'].invoke
    Rake::Task['scraper:areas'].invoke(threads)
    Rake::Task['scraper:disciplines'].invoke(threads)
    Rake::Task['scraper:pre_requisites'].invoke(threads)
    Rake::Task['scraper:classes'].invoke(threads)
    Rake::Task['scraper:discipline_infos'].invoke(threads)
  end

  desc 'Scrapes courses info from a public courses list'
  task courses: :environment do
    puts '-> Starting courses scraping...'

    courses_scraper = Scrapers::Courses.new
    courses = courses_scraper.scrape

    puts "    #{courses} courses found"
    puts '      of ~120 expected'

    puts '-> Finished'
  end

  desc 'Scrapes course areas from SUPAC'
  task :areas, [:threads] => [:environment] do |_, args|
    threads = args[:threads]&.to_i || default_thread_count

    puts '-> Starting areas scraping...'

    areas_scraper = Scrapers::Areas.new(threads:)
    areas = areas_scraper.scrape

    puts "    #{areas} areas found"
    puts '      of 8 expected'

    orphan_courses = Course.where(area: nil)

    puts "    #{orphan_courses.size} orphan courses remain"
    puts '      of 2 expected'

    puts '-> Finished'
  end

  desc 'Scrape the disciplines of every known course'
  task :disciplines, [:threads] => [:environment] do |_, args|
    threads = args[:threads]&.to_i || default_thread_count

    puts '-> Starting disciplines scraping...'

    disciplines_scraper = Scrapers::Disciplines.new(threads:)
    disciplines = disciplines_scraper.scrape

    puts "    #{disciplines} disciplines found"
    puts '      of ~6383 expected'

    course_disciplines = CourseDiscipline.all

    puts "    #{course_disciplines.size} course disciplines found"
    puts '      of ~12553 expected'

    courses_without_disciplines = Course.where.not(id: CourseDiscipline.select(:course_id))

    puts "    #{courses_without_disciplines.size} courses without disciplines found"
    puts '      of 0 expected'

    puts '-> Finished'
  end

  desc 'Crawl the disciplines of every known course'
  task :pre_requisites, [:threads] => [:environment] do |_, args|
    threads = args[:threads]&.to_i || default_thread_count

    puts '-> Starting pre requisites scraping...'

    pre_requisites_scraper = Scrapers::PreRequisites.new(threads:)
    pre_requisites = pre_requisites_scraper.scrape

    puts "    #{pre_requisites} pre requisite links between disciplines"
    puts '      of ~8069 expected'

    pre_disciplines  = CourseDiscipline.where(id: PreRequisite.select(:pre_discipline_id))
    post_disciplines = CourseDiscipline.where(id: PreRequisite.select(:post_discipline_id))
    course_disciplines         = pre_disciplines.or(post_disciplines)
    courses_without_requisites = Course.where.not(id: course_disciplines.select(:course_id))

    puts "    #{courses_without_requisites.size} courses without pre requisites found"
    puts '      of ~15 expected'

    puts '-> Finished'
  end

  desc 'Scrape additional infos for every known discipline'
  task :discipline_infos, [:threads] => [:environment] do |_, args|
    threads = args[:threads]&.to_i || default_thread_count

    puts '-> Starting discipline infos scraping...'

    discipline_infos_scraper = Scrapers::DisciplineInfos.new(threads:)
    updated_disciplines = discipline_infos_scraper.scrape

    puts "    #{updated_disciplines} disciplines with hours"
    puts '      of ~6075 expected'

    disciplines_without_hours = Discipline.where(hours: nil)

    puts "    #{disciplines_without_hours.size} disciplines without hours"
    puts '      of ~308 expected'

    puts '-> Finished'
  end

  desc 'Scrape classes and schedule from the SUPAC schedule guides'
  task :classes, [:threads] => [:environment] do |_, args|
    threads = args[:threads]&.to_i || default_thread_count

    puts '-> Starting classes scraping...'

    classes_scraper = Scrapers::Classes.new(threads:)
    discipline_classes = classes_scraper.scrape

    puts "    #{discipline_classes} classes found"
    puts '      of ~9437 expected'

    discipline_offers = DisciplineClassOffer.all

    puts "    #{discipline_offers.size} discipline offers found"
    puts '      of ~9479 expected'

    course_offers = CourseClassOffer.all

    puts "    #{course_offers.size} course offers found"
    puts '      of ~17109 expected'

    disciplines_without_classes = Discipline.where.not(id: DisciplineClass.select(:discipline_id))

    puts "    #{disciplines_without_classes.size} disciplines without classes found"
    puts '      of ~3033 expected'

    courses_without_classes = Course.where.not(id: CourseClassOffer.select(:course_id))

    puts "    #{courses_without_classes.size} courses without classes found"
    puts '      of ~12 expected'

    schedules = Schedule.all

    puts "    #{schedules.size} schedules found"
    puts '      of ~16807 expected'

    professors = Professor.all

    puts "    #{professors.size} professors found"
    puts '      of ~2714 expected'

    puts '-> Finished'
  end

  ### HELPERS ###

  def default_thread_count
    processor_cores = `grep -c processor /proc/cpuinfo`.to_i
    [4, processor_cores].min
  end
end
