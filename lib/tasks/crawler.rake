namespace :crawler do
  # desc "Utils to convert the current data from Ad model to ClassifiedAd model"
  # task :test_ranking => :environment do
  #   search = Ad.search do
  #     fulltext "teste" do
  #       boost(function {product(:images_count, 2)})
  #       boost(1.5) { with(:has_price_unit, true) }
  #     end
  #   end
  # end
  desc 'Crawl computer science classes page'
  task :cs_classes => :environment do
    course = Course.find_by_code '112'
    unless course
      course = Course.new
      course.code = '112'
      course.name = 'Ciência da Computação'
      course.save
    end

    require 'rubygems'
    require 'mechanize'

    agent = Mechanize.new
    page = agent.get 'https://alunoweb.ufba.br/SiacWWW/CurriculoCursoGradePublico.do?cdCurso=112140&nuPerCursoInicial=20132'
    page = page.links[0].click

    table = page.search('table')[0]
    rows = table.css('tr')[2..-1]
    #puts rows.inspect

    semester = 1
    rows.each do |row|
      columns = row.css('td')

      semester = columns[0].css('b').text[0].to_i unless columns[0].css('b').text.blank?
      nature = columns[1].text
      code = columns[2].text
      name = columns[3].css('a').text.strip
      requisites = columns[4].text
      requisites = requisites == '--' ? [] : requisites.split(', ')

      discipline = Discipline.find_by_code code

      unless discipline
        discipline = Discipline.new
        discipline.code = code
        discipline.name = name
        discipline.requisites = requisites.join '|'
        discipline.save

        course_discipline = CourseDiscipline.new
        course_discipline.semester = semester
        course_discipline.nature = nature
        course_discipline.discipline = discipline
        course_discipline.course = course
        course_discipline.save
      end
    end
  end
end