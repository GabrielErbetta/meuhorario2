Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

=begin
  root 'application#updating'
  get '*path' => redirect('/')
=end

  root 'areas#index'

  get 'contato' => 'application#contact', :as => 'contact_us'
  post 'contato' => 'application#send_contact', :as => 'send_contact'

  get 'area/:id' => 'areas#show', :as => 'area'

  get 'curso/:code' => 'courses#show', :as => 'course_page'

  get 'disciplinas/buscar' => 'disciplines#ajax_search', :as => 'discipline_ajax_search'
  get 'disciplinas/' => 'disciplines#get_information', :as => 'discipline_get_information'

  get 'exportar_grade' => 'application#export_schedule_pdf', :as => 'export_schedule_pdf'

  get 'admin' => 'admin#index'
  get 'crawl_courses' => 'admin#crawl_courses', :as => 'crawl_courses'
  get 'crawl_areas' => 'admin#crawl_areas', :as => 'crawl_areas'
  get 'crawl_disciplines' => 'admin#crawl_disciplines', :as => 'crawl_disciplines'
  get 'crawl_pre_reqs' => 'admin#crawl_pre_reqs', :as => 'crawl_pre_reqs'
  get 'crawl_classes' => 'admin#crawl_classes', :as => 'crawl_classes'
  get 'titleize' => 'admin#titleize', :as => 'titleize'
  get 'clear_db' => 'admin#clear_db', :as => 'clear_db'
end
