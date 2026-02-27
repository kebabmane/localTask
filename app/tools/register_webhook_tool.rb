# frozen_string_literal: true

class RegisterWebhookTool < ApplicationTool
  description "Register or update a webhook URL for agent notifications. Events will be POSTed to the URL as JSON."

  annotations(
    title: "Register Webhook",
    read_only_hint: false,
    open_world_hint: true
  )

  arguments do
    required(:agent_identifier).filled(:string).description("Agent identifier (e.g., 'claude-code')")
    required(:url).filled(:string).description("Webhook callback URL (must be http or https)")
    optional(:secret).filled(:string).description("Optional HMAC secret for payload signature verification via X-Webhook-Signature header")
    optional(:event_types).description("Array of event types to subscribe to: task_assigned, status_changed, mentioned. Omit for all events.")
  end

  def call(agent_identifier:, url:, secret: nil, event_types: nil)
    webhook = AgentWebhook.find_or_initialize_by(
      agent_identifier: agent_identifier,
      url: url
    )
    webhook.secret = secret if secret
    webhook.event_types = event_types if event_types
    webhook.active = true
    webhook.failures = 0
    webhook.save!

    {
      id: webhook.id,
      agent: webhook.agent_identifier,
      url: webhook.url,
      active: webhook.active,
      event_types: webhook.event_types,
      message: webhook.previously_new_record? ? "Webhook registered" : "Webhook updated"
    }
  end
end
