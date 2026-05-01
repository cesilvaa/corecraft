Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "mempool/summary", to: "mempool#summary"
  end

  root "application#status"
end
