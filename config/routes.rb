Rails.application.routes.draw do
  root "pages#index"
  get "new-design" => "pages#new_design", as: :new_design

  devise_for :users, skip: %i[sessions registrations passwords]
  devise_scope :user do
    get "login" => "devise/sessions#new", as: :new_user_session
    post "login" => "devise/sessions#create", as: :user_session
    delete "logout" => "devise/sessions#destroy", as: :destroy_user_session

    get "register" => "devise/registrations#new", as: :new_user_registration
    post "register" => "devise/registrations#create", as: :user_registration
    get "account" => "users/registrations#edit", as: :edit_user_registration
    patch "account" => "users/registrations#update"
    put "account" => "users/registrations#update"
    delete "account" => "users/registrations#destroy"
    get "account/cancel" => "devise/registrations#cancel", as: :cancel_user_registration

    get "password/new" => "devise/passwords#new", as: :new_user_password
    get "password/edit" => "devise/passwords#edit", as: :edit_user_password
    post "password" => "devise/passwords#create", as: :user_password
    patch "password" => "devise/passwords#update"
    put "password" => "devise/passwords#update"
  end

  get "settings" => "settings#edit", as: :settings
  patch "settings" => "settings#update"

  # Stable workspace entry points. When a pet exists they forward to its section;
  # for a brand-new account they render a useful empty state instead of /pets.
  get "journal" => "workspace_sections#journal", as: :journal_overview
  get "reminders" => "workspace_sections#reminders", as: :reminders_overview
  get "documents" => "workspace_sections#documents", as: :documents_overview

  resources :notification_channels, except: %i[show] do
    post :test, on: :member
    post "deliveries/:delivery_id/retry", action: :retry_delivery, on: :collection, as: :retry_delivery
    patch :settings, on: :collection, action: :update_settings
  end
  post "telegram/webhook" => "telegram_webhooks#create", as: :telegram_webhook
  resource :web_push_subscription, only: %i[create destroy]
  resources :pet_tags, path: "pet-tags", only: :index
  get "p/:token" => "public_pet_tags#show", as: :public_pet_tag
  post "p/:token/location" => "public_pet_tags#location", as: :public_pet_tag_location
  get "share/:token" => "public_pet_profile_shares#show", as: :public_pet_profile_share
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resources :pets, only: %i[index show new create edit update] do
    resource :pet_tag, path: :tag, only: %i[show create edit update] do
      patch :rotate_token
      patch :mark_lost
      patch :mark_found
      patch :mark_reunited
      patch :mark_safe
      get "qr.:format" => "pet_tags#qr", as: :qr, constraints: { format: /svg|png/ }
    end
    resources :pet_events, path: :events
    resources :pet_documents, path: :documents do
      patch :sync_journal_event, on: :member
      patch :sync_expiry_reminder, on: :member
      delete "files/:attachment_id", action: :destroy_file, on: :member, as: :file
    end
    resources :profile_shares, controller: :pet_profile_shares do
      patch :enable, on: :member
      patch :disable, on: :member
      patch :rotate_token, on: :member
      get "qr.:format" => "pet_profile_shares#qr", as: :qr, on: :member, constraints: { format: /svg|png/ }
    end
    resources :reminders do
      patch :complete, on: :member
      patch :pause, on: :member
      patch :resume, on: :member
      patch :snooze, on: :member
    end
  end
end
