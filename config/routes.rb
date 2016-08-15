Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'application#index'
  get 'curso/:code' => 'courses#show', :as => 'course_page'
  get 'clear_db' => 'application#clear_db', :as => 'clear_db'
  get 'crawl_courses' => 'application#crawl_courses', :as => 'crawl_courses'
  get 'crawl_disciplines' => 'application#crawl_disciplines', :as => 'crawl_disciplines'
end
