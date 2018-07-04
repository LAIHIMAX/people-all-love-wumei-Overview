Rails.application.routes.draw do
  devise_for :users
  resources :keyword_mappings
  resources :push_messages, only: [:new, :create]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  post '/kamigo/webhook', to: 'kamigo#webhook'  
end
