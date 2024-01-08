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

  def crawl_classes
    call_rake 'scraper:all'
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
