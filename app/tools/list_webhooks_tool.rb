# frozen_string_literal: true

class ListWebhooksTool < ApplicationTool
  description "List registered webhooks for an agent"

  annotations(
    title: "List Webhooks",
    read_only_hint: true,
    open_world_hint: false
  )

  arguments do
    required(:agent_identifier).filled(:string).description("Agent identifier (e.g., 'claude-code')")
  end

  def call(agent_identifier:)
    webhooks = AgentWebhook.for_agent(agent_identifier)

    {
      agent: agent_identifier,
      webhooks: webhooks.map { |w|
        {
          id: w.id,
          url: w.url,
          active: w.active,
          event_types: w.event_types,
          failures: w.failures,
          last_delivered_at: w.last_delivered_at&.iso8601
        }
      }
    }
  end
end
