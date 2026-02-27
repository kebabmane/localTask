# frozen_string_literal: true

class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5
  discard_on ActiveRecord::RecordNotFound

  def perform(webhook_id, notification_id)
    webhook = AgentWebhook.find(webhook_id)
    notification = AgentNotification.find(notification_id)

    return unless webhook.active?

    uri = URI.parse(webhook.url)
    payload = notification.payload.to_json
    headers = build_headers(webhook, payload)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = payload

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      webhook.record_success!
    else
      webhook.record_failure!
      # Re-raise on server errors to trigger retry
      raise "Webhook delivery failed: #{response.code} #{response.message}" if response.code.to_i >= 500
    end
  end

  private

  def build_headers(webhook, payload)
    headers = {
      "Content-Type" => "application/json",
      "User-Agent" => "LocalTask-Webhook/1.0",
      "X-LocalTask-Event" => "agent_notification"
    }
    if webhook.secret.present?
      signature = OpenSSL::HMAC.hexdigest("SHA256", webhook.secret, payload)
      headers["X-Webhook-Signature"] = "sha256=#{signature}"
    end
    headers
  end
end
