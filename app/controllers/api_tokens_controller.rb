class ApiTokensController < ApplicationController
  def index
    @api_tokens = Current.user.api_tokens.order(created_at: :desc)
  end

  def create
    @token = Current.user.api_tokens.build(token_params)

    if @token.save
      flash[:token] = @token.raw_token
      redirect_to api_tokens_path, notice: "Token created. Copy it now - it won't be shown again."
    else
      @api_tokens = Current.user.api_tokens.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @token = Current.user.api_tokens.find(params[:id])
    @token.destroy
    redirect_to api_tokens_path, notice: "Token revoked."
  end

  private

  def token_params
    params.require(:api_token).permit(:name)
  end
end
