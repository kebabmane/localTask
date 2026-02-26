module Api
  module V1
    class ProfileController < BaseController
      def show
        render json: {
          id: @current_user.id,
          name: @current_user.name,
          email: @current_user.email_address,
          role: @current_user.role,
          projects_count: @current_user.projects.count,
          token_name: @current_api_token.name,
          token_prefix: @current_api_token.prefix
        }
      end
    end
  end
end
