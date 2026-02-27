# frozen_string_literal: true

class GetAgentNotificationsTool < ApplicationTool
  description "Check for pending notifications for an agent. Returns unread events like task assignments, status changes, and @mentions."

  annotations(
    title: "Get Agent Notifications",
    read_only_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:agent_identifier).filled(:string).description("Agent identifier (e.g., 'claude-code')")
    optional(:unread_only).filled(:bool).description("Only return unread notifications (default: true)")
    optional(:limit).filled(:integer).description("Max notifications to return (default: 20, max: 100)")
    optional(:mark_as_read).filled(:bool).description("Mark returned notifications as read (default: true)")
  end

  def call(agent_identifier:, unread_only: true, limit: 20, mark_as_read: true)
    limit = [limit.to_i, 100].min
    limit = 20 if limit <= 0

    notifications = AgentNotification.for_agent(agent_identifier).recent.limit(limit)
    notifications = notifications.unread if unread_only

    result = notifications.map do |n|
      {
        id: n.id,
        event_type: n.event_type,
        task_id: n.task_id,
        task_display_id: n.task.display_id,
        message: n.message,
        read: n.read,
        created_at: n.created_at.iso8601
      }
    end

    if mark_as_read
      notifications.unread.update_all(read: true, read_at: Time.current)
    end

    { agent: agent_identifier, notifications: result, count: result.size }
  end
end
