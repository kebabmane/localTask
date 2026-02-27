module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    helper_method :admin_nav_items, :current_admin_section

    private

    def require_admin
      unless Current.user&.admin?
        redirect_to root_path, alert: "You don't have permission to access the admin area."
      end
    end

    def admin_nav_items
      [
        { key: :dashboard, label: "Overview", path: admin_path, icon: "chart_bar" },
        { key: :users, label: "Users", path: admin_users_path, icon: "users" },
        { key: :agents, label: "Agents", path: admin_agents_path, icon: "cpu_chip" },
        { key: :api_tokens, label: "API Tokens", path: admin_api_tokens_path, icon: "key" },
        { key: :webhooks, label: "Webhooks", path: admin_webhooks_path, icon: "arrow_path" },
        { key: :system, label: "System", path: admin_system_path, icon: "server" }
      ]
    end

    def current_admin_section
      :dashboard
    end
  end
end
