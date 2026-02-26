Rails.application.routes.draw do
  # Authentication
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [:new, :create]

  # Projects and Kanban
  resources :projects do
    resources :task_statuses, only: [:create, :update, :destroy], path: "statuses"
    resources :tasks do
      resources :comments, only: [:create, :destroy]
      resource :position, only: [:update], controller: "task_positions"
    end
    get "board", to: "boards#show"
  end

  # API Token management
  resources :api_tokens, only: [:index, :create, :destroy]

  # API
  namespace :api do
    namespace :v1 do
      resources :projects, only: [:index, :show, :create, :update] do
        resources :tasks, only: [:index, :show, :create, :update, :destroy] do
          resources :comments, only: [:index, :create], controller: "comments"
          resource :status, only: [:update], controller: "task_statuses"
        end
        resources :statuses, only: [:index], controller: "task_statuses"
      end
      resource :me, only: [:show], controller: "profile"
    end
  end

  # Dashboard
  root "dashboards#show"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
