# frozen_string_literal: true

class AgentWebhookSerializer
  def initialize(webhook)
    @webhook = webhook
  end

  def as_json(*)
    {
      id: @webhook.id,
      agent_identifier: @webhook.agent_identifier,
      url: @webhook.url,
      active: @webhook.active,
      event_types: @webhook.event_types,
      failures: @webhook.failures,
      last_delivered_at: @webhook.last_delivered_at&.iso8601,
      last_failed_at: @webhook.last_failed_at&.iso8601,
      created_at: @webhook.created_at.iso8601
    }
  end
end
