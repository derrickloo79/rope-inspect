Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]
  devise_for :fsps, skip: [ :registrations ], path: "fsp", path_names: {
    sign_in: "sign_in",
    sign_out: "sign_out"
  }, controllers: {
    sessions: "fsps/sessions"
  }

  # Public intake
  resources :inspection_requests, only: [ :new, :create ] do
    collection do
      get :thank_you
    end
  end

  # Public shareable status timeline (token-based)
  get "status/:token", to: "status#show", as: :public_status

  # Internal staff dashboard
  namespace :dashboard do
    root to: "home#index"
    get "planner", to: "planner#index", as: :planner
    resource :profile, only: [ :edit, :update ]
    resources :users, path: "admins", except: [ :show ]
    resources :fsps, path: "fsps", except: [ :show ]
    resources :inspection_requests, only: [ :index, :show ], path: "jobs" do
      member do
        patch :accept
        patch :reject
        patch :reopen
        patch :schedule
        patch :complete
        patch :site_access
      end
    end
  end

  # FSP portal — inspectors view only their assigned jobs
  namespace :portal do
    root to: "jobs#index"
    resources :jobs, only: [ :index, :show ]
  end

  root "inspection_requests#new"

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
