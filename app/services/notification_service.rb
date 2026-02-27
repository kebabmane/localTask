# frozen_string_literal: true

class NotificationService
  def self.task_assigned(task)
    return if task.agent_identifier.blank?

    notification = AgentNotification.create!(
      agent_identifier: task.agent_identifier,
      event_type: "task_assigned",
      task: task,
      message: "Task #{task.display_id} '#{task.title}' was assigned to you",
      payload: {
        event: "task_assigned",
        task_id: task.id,
        display_id: task.display_id,
        title: task.title,
        project: task.project.name,
        status: task.task_status.name,
        priority: task.priority,
        assigned_at: Time.current.iso8601
      }
    )

    dispatch_webhooks(notification)
  end

  def self.status_changed(task, old_status_name, new_status_name)
    agents = involved_agents(task)
    agents.each do |agent_id|
      notification = AgentNotification.create!(
        agent_identifier: agent_id,
        event_type: "status_changed",
        task: task,
        message: "Task #{task.display_id} status changed from '#{old_status_name}' to '#{new_status_name}'",
        payload: {
          event: "status_changed",
          task_id: task.id,
          display_id: task.display_id,
          title: task.title,
          old_status: old_status_name,
          new_status: new_status_name,
          changed_at: Time.current.iso8601
        }
      )
      dispatch_webhooks(notification)
    end
  end

  def self.agent_mentioned(comment, agent_identifier)
    notification = AgentNotification.create!(
      agent_identifier: agent_identifier,
      event_type: "mentioned",
      task: comment.task,
      comment: comment,
      message: "You were mentioned in a comment on #{comment.task.display_id}",
      payload: {
        event: "mentioned",
        task_id: comment.task_id,
        display_id: comment.task.display_id,
        comment_id: comment.id,
        comment_body: comment.body,
        author: comment.author_name,
        mentioned_at: Time.current.iso8601
      }
    )
    dispatch_webhooks(notification)
  end

  def self.task_cross_referenced(comment, referenced_task)
    agents = involved_agents(referenced_task)
    agents.each do |agent_id|
      notification = AgentNotification.create!(
        agent_identifier: agent_id,
        event_type: "mentioned",
        task: referenced_task,
        comment: comment,
        message: "Task #{referenced_task.display_id} was referenced in a comment on #{comment.task.display_id}",
        payload: {
          event: "mentioned",
          task_id: referenced_task.id,
          display_id: referenced_task.display_id,
          referencing_task_id: comment.task_id,
          referencing_display_id: comment.task.display_id,
          comment_id: comment.id,
          comment_body: comment.body,
          author: comment.author_name,
          referenced_at: Time.current.iso8601
        }
      )
      dispatch_webhooks(notification)
    end
  end

  def self.dispatch_webhooks(notification)
    webhooks = AgentWebhook.active.for_agent(notification.agent_identifier)
    webhooks.each do |webhook|
      next unless webhook.subscribes_to?(notification.event_type)
      WebhookDeliveryJob.perform_later(webhook.id, notification.id)
    end
  end

  # Returns array of agent_identifier strings involved with a task
  def self.involved_agents(task)
    agents = []
    agents << task.agent_identifier if task.agent_identifier.present?
    comment_agents = task.comments.where.not(agent_identifier: [nil, ""])
                         .pluck(:agent_identifier).uniq
    (agents + comment_agents).uniq
  end

  private_class_method :dispatch_webhooks, :involved_agents
end
