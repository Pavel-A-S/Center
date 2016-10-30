Rails.application.routes.draw do
  resources :car_records
  resources :user_records
  resources :event_records
  resources :ports

  resources :locations do
    member do
      get :page
    end

    collection do
      get :user_index
    end
  end

  resources :connections
  devise_for :users

  scope "/admin" do
    resources :users
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'locations#user_index'
  post 'command_handler', to: 'commands#command_handler', as: 'command_handler'
  post 'siren', to: 'commands#siren', as: 'siren'
end
