class AdminController < ApplicationController
  before_action :authenticate

  def index
  end

  def clear_db
    CourseDiscipline.destroy_all
    Discipline.destroy_all
    Course.destroy_all

    render 'index'
  end

  def crawl_courses
    call_rake 'scraper:courses'
    render 'index'
  end

  def crawl_areas
    call_rake 'scraper:areas'
    render 'index'
  end

  def crawl_disciplines
    call_rake 'scraper:disciplines'
    render 'index'
  end

  def crawl_pre_reqs
    call_rake 'scraper:pre_requisites'
    render 'index'
  end

  def crawl_classes
    call_rake 'scraper:classes'
    render 'index'
  end

  def titleize
    call_rake 'scraper:titleize'
    render 'index'
  end

  private
    def call_rake(task, options = {})
      options[:rails_env] ||= Rails.env
      args = options.map { |n, v| "#{n.to_s.upcase}='#{v}'" }
      system "rake #{task} #{args.join(' ')} >> #{Rails.root}/log/rake.log 2>&1 &"
    end

  protected
    def authenticate
      if Rails.env.production?
        authenticate_or_request_with_http_basic do |username, password|
          username == ENV["ADMIN_USERNAME"] && password == ENV["ADMIN_PASSWORD"]
        end
      end
    end
end
