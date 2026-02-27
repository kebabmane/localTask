module Admin
  class AgentsController < BaseController
    def index
      @agents = discover_agents.map { |id| build_agent_summary(id) }
                               .sort_by { |a| a[:last_active] || Time.at(0) }
                               .reverse
    end

    def show
      @identifier = params[:id]

      @tasks = Task.by_agent(@identifier)
                   .includes(:project, :task_status)
                   .order(updated_at: :desc).limit(50)
      @webhooks = AgentWebhook.for_agent(@identifier).order(created_at: :desc)
      @notifications = AgentNotification.for_agent(@identifier)
                           .recent.limit(50)
      @comments = Comment.where(agent_identifier: @identifier)
                         .includes(:task).order(created_at: :desc).limit(20)

      @stats = {
        tasks_total: Task.by_agent(@identifier).count,
        tasks_open: Task.by_agent(@identifier).open.count,
        tasks_closed: Task.by_agent(@identifier).closed.count,
        comments: Comment.where(agent_identifier: @identifier).count,
        webhooks_active: @webhooks.active.count,
        notifications_unread: AgentNotification.for_agent(@identifier).unread.count,
        first_seen: first_seen(@identifier),
        last_active: last_activity(@identifier)
      }
    end

    private

    def current_admin_section = :agents

    def discover_agents
      identifiers = Set.new
      identifiers.merge(Task.where.not(agent_identifier: [nil, ""])
                             .distinct.pluck(:agent_identifier))
      identifiers.merge(AgentWebhook.distinct.pluck(:agent_identifier))
      identifiers.merge(AgentNotification.distinct.pluck(:agent_identifier))
      identifiers.merge(Comment.where.not(agent_identifier: [nil, ""])
                                .distinct.pluck(:agent_identifier))
      identifiers.merge(Mention.where.not(agent_identifier: [nil, ""])
                                .distinct.pluck(:agent_identifier))
      identifiers.to_a.sort
    end

    def build_agent_summary(identifier)
      {
        identifier: identifier,
        tasks_count: Task.by_agent(identifier).count,
        open_tasks: Task.by_agent(identifier).open.count,
        webhooks_count: AgentWebhook.for_agent(identifier).active.count,
        unread_notifications: AgentNotification.for_agent(identifier).unread.count,
        last_active: last_activity(identifier)
      }
    end

    def last_activity(identifier)
      [
        Task.by_agent(identifier).maximum(:updated_at),
        Comment.where(agent_identifier: identifier).maximum(:created_at),
        AgentWebhook.for_agent(identifier).maximum(:last_delivered_at)
      ].compact.max
    end

    def first_seen(identifier)
      [
        Task.by_agent(identifier).minimum(:created_at),
        Comment.where(agent_identifier: identifier).minimum(:created_at),
        AgentWebhook.for_agent(identifier).minimum(:created_at)
      ].compact.min
    end
  end
end
