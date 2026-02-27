# frozen_string_literal: true

class AgentNotificationSerializer
  def initialize(notification)
    @notification = notification
  end

  def as_json(*)
    {
      id: @notification.id,
      agent_identifier: @notification.agent_identifier,
      event_type: @notification.event_type,
      task_id: @notification.task_id,
      task_display_id: @notification.task.display_id,
      comment_id: @notification.comment_id,
      message: @notification.message,
      payload: @notification.payload,
      read: @notification.read,
      read_at: @notification.read_at&.iso8601,
      created_at: @notification.created_at.iso8601
    }
  end
end
