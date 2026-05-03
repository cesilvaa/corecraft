Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "mempool/summary",   to: "mempool#summary"
    get "blockchain/lag",    to: "blockchain#lag"
    get "events/summary",    to: "events#summary"
  end

  get "panel", to: "panel#index"

  root "application#status"
end
