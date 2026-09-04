Rails.application.routes.draw do
  root "pages#index"
  get "new-design" => "pages#new_design", as: :new_design
  get "privacy" => "legal#privacy", as: :privacy
  get "personal-data-consent" => "legal#personal_data_consent", as: :personal_data_consent
  get "pet-tag-data-consent" => "legal#pet_tag_finder_consent", as: :pet_tag_data_consent
  get "pet-tag-phone-distribution-consent" => "legal#pet_tag_phone_distribution_consent", as: :pet_tag_phone_distribution_consent

  if Rails.env.development?
    get "error-preview/:status" => "errors#show",
        as: :error_preview,
        constraints: { status: /404|406|422|500/ }

    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  devise_for :users, skip: %i[sessions registrations passwords]
  devise_scope :user do
    get "login" => "devise/sessions#new", as: :new_user_session
    post "login" => "devise/sessions#create", as: :user_session
    delete "logout" => "devise/sessions#destroy", as: :destroy_user_session

    get "register" => "users/registrations#new", as: :new_user_registration
    post "register" => "users/registrations#create", as: :user_registration
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

  resources :notifications, controller: :in_app_notifications, only: %i[index show] do
    patch :mark_all_read, on: :collection
  end

  # Stable cross-pet workspace entry points. A specific pet is selected via a
  # query parameter while nested routes remain available for CRUD operations.
  get "journal" => "pet_events#index", as: :journal_overview
  get "reminders" => "reminders#index", as: :reminders_overview
  get "documents" => "pet_documents#index", as: :documents_overview
  get "public-access" => "workspace_sections#public_access", as: :public_access_overview

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
  # Can be used by load balancers and uptime monitors to verify the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* with explicit response formats.
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker, defaults: { format: :js }
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }

  resources :pets, only: %i[index show new create edit update destroy] do
    resource :pet_tag, path: :tag, only: %i[show create edit update] do
      patch :rotate_token
      patch :mark_lost
      patch :mark_found
      patch :mark_reunited
      patch :mark_safe
      get :phone_consent, path: "phone-consent"
      post :publish_phone, path: "phone-consent"
      delete :revoke_phone, path: "phone-consent"
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
