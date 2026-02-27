module Admin
  class DashboardController < BaseController
    def show
      @stats = {
        users: User.count,
        projects: Project.count,
        tasks_open: Task.open.count,
        tasks_completed: Task.closed.count,
        tasks_deleted: Task.only_deleted.count,
        agents_active: active_agent_identifiers.size,
        api_tokens_active: ApiToken.active.count,
        api_tokens_total: ApiToken.count,
        webhooks_active: AgentWebhook.active.count,
        webhooks_failing: AgentWebhook.where("failures > 0").count,
        notifications_unread: AgentNotification.unread.count
      }

      @recent_tasks = Task.includes(:project, :task_status)
                          .order(created_at: :desc).limit(10)
      @recent_users = User.order(created_at: :desc).limit(5)
      @active_agents = active_agent_identifiers.first(5).map do |identifier|
        {
          identifier: identifier,
          tasks_count: Task.by_agent(identifier).count,
          last_active: last_activity_for(identifier)
        }
      end
    end

    private

    def current_admin_section = :dashboard

    def active_agent_identifiers
      @active_agent_identifiers ||= begin
        from_tasks = Task.where.not(agent_identifier: [nil, ""])
                         .distinct.pluck(:agent_identifier)
        from_webhooks = AgentWebhook.distinct.pluck(:agent_identifier)
        from_comments = Comment.where.not(agent_identifier: [nil, ""])
                               .distinct.pluck(:agent_identifier)
        (from_tasks + from_webhooks + from_comments).uniq.sort
      end
    end

    def last_activity_for(identifier)
      [
        Task.by_agent(identifier).maximum(:updated_at),
        Comment.where(agent_identifier: identifier).maximum(:created_at),
        AgentWebhook.for_agent(identifier).maximum(:last_delivered_at)
      ].compact.max
    end
  end
end
