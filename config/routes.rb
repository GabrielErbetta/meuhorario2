Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'application#index'
  get 'curso/:id' => 'courses#show', :as => 'course_page'
end
