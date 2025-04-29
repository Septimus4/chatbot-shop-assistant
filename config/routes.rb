Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # User authentication (Devise)
  devise_for :users

  # Unified Chat Interface
  resources :chats, only: [:index, :create, :destroy] do
    resources :messages, only: [:create]
  end

  # Custom route to show a selected chat within the index
  get 'chats/:chat_id', to: 'chats#index', as: 'chat_view'

  # Root path
  root "chats#index"
end
