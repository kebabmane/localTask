# frozen_string_literal: true

module Api
  module V1
    class AgentNotificationsController < BaseController
      # GET /api/v1/agent_notifications?agent=claude-code&unread=true
      def index
        notifications = AgentNotification.recent
        notifications = notifications.for_agent(params[:agent]) if params[:agent]
        notifications = notifications.unread if params[:unread] == "true"
        notifications = notifications.limit(params.fetch(:limit, 20).to_i.clamp(1, 100))

        render json: notifications.map { |n| AgentNotificationSerializer.new(n).as_json }
      end

      # PATCH /api/v1/agent_notifications/:id/mark_read
      def mark_read
        notification = AgentNotification.find(params[:id])
        notification.mark_as_read!
        render json: AgentNotificationSerializer.new(notification).as_json
      end

      # POST /api/v1/agent_notifications/mark_all_read?agent=claude-code
      def mark_all_read
        scope = AgentNotification.unread
        scope = scope.for_agent(params[:agent]) if params[:agent]
        count = scope.update_all(read: true, read_at: Time.current)
        render json: { marked_read: count }
      end
    end
  end
end
