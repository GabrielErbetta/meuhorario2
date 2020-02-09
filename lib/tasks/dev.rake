namespace :dev do
  desc 'Seeds the database with 2020.1 data'
  task seed: :environment do
    records = JSON.parse(File.read(Rails.root.join('db', 'dump.json')))

    records.each do |model, objets|
      model_class = model.classify.constantize

      print "Started importing #{model}...   "
      model_class.create!(objets)
      puts 'OK!'
    end
  end
end
