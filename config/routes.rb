Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"

  get "sign_up" => "registrations#new", as: :sign_up
  post "sign_up" => "registrations#create"

  get "sign_in" => "sessions#new", as: :sign_in
  post "sign_in" => "sessions#create"
  delete "sign_out" => "sessions#destroy", as: :sign_out

  resource :password_reset, only: %i[new create], path: "password-reset"
  get "password-reset/:token" => "password_resets#edit", as: :edit_password_reset_token
  patch "password-reset/:token" => "password_resets#update", as: :password_reset_token

  namespace :admin do
    root "airports#index"
    resources :airports, only: %i[index edit update destroy], param: :place_id

    namespace :imports do
      resources :airports, only: %i[index create], controller: "airports"
    end
  end

  get "dashboard" => "dashboard#show", as: :dashboard
end
