# frozen_string_literal: true

class AgentNotification < ApplicationRecord
  belongs_to :task
  belongs_to :comment, optional: true

  validates :agent_identifier, presence: true
  validates :event_type, presence: true,
            inclusion: { in: %w[task_assigned status_changed mentioned] }
  validates :message, presence: true

  scope :unread, -> { where(read: false) }
  scope :for_agent, ->(identifier) { where(agent_identifier: identifier) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end
end
