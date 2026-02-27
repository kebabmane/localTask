module Admin
  class WebhooksController < BaseController
    before_action :set_webhook, only: [:destroy, :toggle_active, :reset_failures]

    def index
      @webhooks = AgentWebhook.order(created_at: :desc)
      @webhooks = @webhooks.active if params[:filter] == "active"
      @webhooks = @webhooks.where(active: false) if params[:filter] == "inactive"
      @webhooks = @webhooks.where("failures > 0") if params[:filter] == "failing"
    end

    def destroy
      @webhook.destroy
      redirect_to admin_webhooks_path, notice: "Webhook deleted."
    end

    def toggle_active
      @webhook.update!(active: !@webhook.active?)
      redirect_to admin_webhooks_path,
        notice: "Webhook #{@webhook.active? ? 'activated' : 'deactivated'}."
    end

    def reset_failures
      @webhook.update!(failures: 0, active: true)
      redirect_to admin_webhooks_path, notice: "Webhook failures reset and reactivated."
    end

    private

    def current_admin_section = :webhooks

    def set_webhook
      @webhook = AgentWebhook.find(params[:id])
    end
  end
end
