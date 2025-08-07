require 'sidekiq/web'

Rails.application.routes.draw do
  # Mount Sidekiq web UI
  mount Sidekiq::Web => '/sidekiq'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # API routes
  namespace :api do
    post "clock_in", to: "clock_ins#clock_in"
    post "clock_out", to: "clock_ins#clock_out"
    get "user_clock_ins", to: "clock_ins#user_clock_ins"
    post "follow_user", to: "clock_ins#follow_user"
    post "unfollow_user", to: "clock_ins#unfollow_user"
    get "followings_clock_ins", to: "clock_ins#followings_clock_ins"
    get "job_status/:job_id", to: "clock_ins#job_status"
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
