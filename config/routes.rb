Rails.application.routes.draw do
  root "events#index"

  resources :events, only: [:index, :show] do
    resources :votes, only: [:create]
  end
  delete "/sign_out" => "application#sign_out"
  get "/sign_out" => "application#sign_out"
  get "up" => "rails/health#show", as: :rails_health_check
end
