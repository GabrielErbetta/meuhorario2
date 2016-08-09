Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'application#index'
  get 'curso/:id' => 'courses#show', :as => 'course_page'
  get 'clear_db' => 'application#clear_db', :as => 'clear_db'
  get 'crawl_cs' => 'application#crawl_cs', :as => 'crawl_cs'
end
