# frozen_string_literal: true

class DeleteWebhookTool < ApplicationTool
  description "Delete a registered webhook"

  annotations(
    title: "Delete Webhook",
    read_only_hint: false,
    open_world_hint: false
  )

  arguments do
    required(:webhook_id).filled(:integer).description("Webhook ID to delete")
  end

  def call(webhook_id:)
    webhook = AgentWebhook.find(webhook_id)
    webhook.destroy!

    { deleted: true, id: webhook_id }
  end
end
