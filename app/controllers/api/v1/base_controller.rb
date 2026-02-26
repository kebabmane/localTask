module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_token!
      rate_limit to: 120, within: 1.minute, by: -> { @current_api_token&.id&.to_s || request.remote_ip }

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity_error
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def authenticate_api_token!
        authenticate_with_http_token do |token, _options|
          @current_api_token = ApiToken.authenticate(token)
          @current_user = @current_api_token&.user
        end

        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable_entity_error(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
