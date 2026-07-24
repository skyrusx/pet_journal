Rails.application.routes.draw do
  get "pet_events/index"
  get "pet_events/show"
  get "pet_events/new"
  get "pet_events/create"
  get "pet_events/edit"
  get "pet_events/update"
  get "pet_events/destroy"
  root "pages#index"
  devise_for :users
  resources :notification_channels, except: %i[show] do
    post :test, on: :member
    patch :settings, on: :collection, action: :update_settings
  end
  resource :web_push_subscription, only: %i[create destroy]
  get "p/:token" => "public_pet_tags#show", as: :public_pet_tag
  post "p/:token/location" => "public_pet_tags#location", as: :public_pet_tag_location
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  resources :pets, only: %i[index show new create edit update] do
    resource :pet_tag, path: :tag, only: %i[show create edit update] do
      patch :rotate_token
      patch :mark_lost
      patch :mark_found
      patch :mark_reunited
      get "qr.:format" => "pet_tags#qr", as: :qr, constraints: { format: /svg|png/ }
    end
    resources :pet_events, path: :events
    resources :pet_documents, path: :documents do
      delete "files/:attachment_id", action: :destroy_file, on: :member, as: :file
    end
    resources :reminders do
      patch :complete, on: :member
      patch :pause, on: :member
      patch :resume, on: :member
      patch :snooze, on: :member
    end
  end
end
