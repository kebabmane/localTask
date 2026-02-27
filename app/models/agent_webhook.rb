# frozen_string_literal: true

class AgentWebhook < ApplicationRecord
  MAX_FAILURES = 10

  validates :agent_identifier, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/.+\z/i, message: "must be a valid HTTP(S) URL" }
  validates :failures, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :for_agent, ->(identifier) { where(agent_identifier: identifier) }

  def subscribes_to?(event_type)
    event_types.blank? || event_types.include?(event_type)
  end

  def record_success!
    update!(failures: 0, last_delivered_at: Time.current)
  end

  def record_failure!
    new_failures = failures + 1
    update!(
      failures: new_failures,
      last_failed_at: Time.current,
      active: new_failures < MAX_FAILURES
    )
  end
end
