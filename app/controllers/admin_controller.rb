class AdminController < ApplicationController
  before_filter :authenticate

  def index
  end

  def clear_db
    CourseDiscipline.destroy_all
    Discipline.destroy_all
    Course.destroy_all

    render 'index'
  end

  def crawl_cs
    call_rake 'crawler:cs_disciplines'
    render 'index'
  end

  def crawl_courses
    call_rake 'crawler:courses'
    render 'index'
  end

  def crawl_areas
    call_rake 'crawler:areas'
    render 'index'
  end

  def crawl_disciplines
    call_rake 'crawler:disciplines'
    render 'index'
  end

  def crawl_pre_reqs
    call_rake 'crawler:pre_requisites'
    render 'index'
  end

  def crawl_cs_classes
    call_rake 'crawler:cs_classes'
    render 'index'
  end

  def crawl_classes
    call_rake 'crawler:classes'
    render 'index'
  end

  def titleize
    call_rake 'crawler:titleize'
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
