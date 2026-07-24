Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  # Public intake
  resources :inspection_requests, only: [ :new, :create ] do
    collection do
      get :thank_you
    end
  end

  # Public shareable status timeline (token-based)
  get "status/:token", to: "status#show", as: :public_status

  # Internal dashboard
  namespace :dashboard do
    resources :inspection_requests, only: [ :index, :show ] do
      member do
        patch :accept
        patch :schedule
        patch :complete
      end
    end
    root to: "inspection_requests#index"
  end

  root "inspection_requests#new"

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
