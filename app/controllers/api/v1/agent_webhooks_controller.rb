# frozen_string_literal: true

module Api
  module V1
    class AgentWebhooksController < BaseController
      # GET /api/v1/agent_webhooks?agent=claude-code
      def index
        webhooks = AgentWebhook.all
        webhooks = webhooks.for_agent(params[:agent]) if params[:agent]
        render json: webhooks.map { |w| AgentWebhookSerializer.new(w).as_json }
      end

      # POST /api/v1/agent_webhooks
      def create
        webhook = AgentWebhook.new(webhook_params)
        webhook.save!
        render json: AgentWebhookSerializer.new(webhook).as_json, status: :created
      end

      # PATCH /api/v1/agent_webhooks/:id
      def update
        webhook = AgentWebhook.find(params[:id])
        webhook.update!(webhook_params)
        render json: AgentWebhookSerializer.new(webhook).as_json
      end

      # DELETE /api/v1/agent_webhooks/:id
      def destroy
        webhook = AgentWebhook.find(params[:id])
        webhook.destroy!
        head :no_content
      end

      private

      def webhook_params
        params.require(:webhook).permit(:agent_identifier, :url, :secret, :active, event_types: [])
      end
    end
  end
end
