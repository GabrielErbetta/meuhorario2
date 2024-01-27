Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

=begin
  root 'application#updating'
  get '*path' => redirect('/')
=end

  root 'areas#index'

  get 'area/:id' => 'areas#show', :as => 'area'

  get 'curso/:code' => 'courses#show', :as => 'course_page'

  get 'disciplinas/buscar' => 'disciplines#ajax_search', :as => 'discipline_ajax_search'
  get 'disciplinas/' => 'disciplines#get_information', :as => 'discipline_get_information'

  get 'exportar_grade' => 'application#export_schedule_pdf', :as => 'export_schedule_pdf'

  get 'admin' => 'admin#index'
  get 'crawl_classes' => 'admin#crawl_classes', :as => 'crawl_classes'
  get 'clear_db' => 'admin#clear_db', :as => 'clear_db'

  # CONTACT
  get 'contato',
      to: 'contact#show',
      as: 'contact_show'
  post 'contato',
       to: 'contact#submit',
       as: 'contact_submit'
end
