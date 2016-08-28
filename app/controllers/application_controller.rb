class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def index
    @courses = Course.all
    @courses ||= []
  end

  def clear_db
    call_rake 'db:reset'
    redirect_to root_path
  end

  def crawl_cs
    call_rake 'crawler:cs_classes'
    redirect_to root_path
  end

  def crawl_courses
    call_rake 'crawler:courses'
    logger.debug "\ncrawling\n"
    redirect_to root_path
  end

  def crawl_disciplines
    call_rake 'crawler:disciplines'
    redirect_to root_path
  end

  def crawl_pre_reqs
    call_rake 'crawler:pre_requisites'
    redirect_to root_path
  end


  private

  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
    system "rake #{task} #{args.join(' ')} >> #{Rails.root}/log/rake.log &"
  end
end
