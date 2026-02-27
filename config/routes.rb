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

  # Agent management
  resources :agents, only: [:index, :new, :create, :show, :destroy] do
    member do
      get :download_config
    end
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

      # Agent hooks
      resources :agent_notifications, only: [:index] do
        member do
          patch :mark_read
        end
        collection do
          post :mark_all_read
        end
      end
      resources :agent_webhooks, only: [:index, :create, :update, :destroy]
    end
  end

  # Admin panel
  namespace :admin do
    get "/", to: "dashboard#show"
    resources :users, only: [:index, :show, :edit, :update]
    resources :agents, only: [:index, :show], constraints: { id: /[^\/]+/ }
    resources :api_tokens, only: [:index, :destroy]
    resources :webhooks, only: [:index, :destroy] do
      member do
        patch :toggle_active
        post :reset_failures
      end
    end
    resource :system, only: [:show], controller: "system"
  end

  # Dashboard
  root "dashboards#show"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
