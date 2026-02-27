class Agent < ApplicationRecord
  belongs_to :user
  belongs_to :api_token, optional: true

  validates :name, presence: true
  validates :identifier, presence: true,
                          uniqueness: true,
                          format: { with: /\A[a-z][a-z0-9_-]*\z/, message: "must start with a lowercase letter and contain only lowercase letters, numbers, hyphens, and underscores" }

  before_validation :generate_identifier, on: :create

  # Convenience accessors via identifier
  def tasks
    Task.by_agent(identifier)
  end

  def webhooks
    AgentWebhook.for_agent(identifier)
  end

  def notifications
    AgentNotification.for_agent(identifier)
  end

  def comments
    Comment.where(agent_identifier: identifier)
  end

  def stats
    {
      tasks_total: tasks.count,
      tasks_open: tasks.open.count,
      tasks_closed: tasks.closed.count,
      webhooks_active: webhooks.active.count,
      notifications_unread: notifications.unread.count,
      comments_count: comments.count
    }
  end

  private

  def generate_identifier
    return if identifier.present?
    return unless name.present?

    base = name.parameterize
    self.identifier = base
  end
end
