module Admin
  class ApiTokensController < BaseController
    def index
      @tokens = ApiToken.includes(:user).order(created_at: :desc)
      @tokens = @tokens.where(active: true) if params[:filter] == "active"
      @tokens = @tokens.where(active: false) if params[:filter] == "revoked"
    end

    def destroy
      @token = ApiToken.find(params[:id])
      @token.update!(active: false)
      redirect_to admin_api_tokens_path, notice: "Token revoked."
    end

    private

    def current_admin_section = :api_tokens
  end
end
