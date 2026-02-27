class AgentsController < ApplicationController
  before_action :set_agent, only: [:show, :destroy, :download_config]

  def index
    @agents = Current.user.agents.includes(:api_token).order(created_at: :desc)
  end

  def new
    @agent = Agent.new
  end

  def create
    @agent = Current.user.agents.build(agent_params)

    Agent.transaction do
      # Auto-create an API token for the agent
      token = Current.user.api_tokens.build(name: "Agent: #{@agent.name}")
      token.save!
      @agent.api_token = token

      if @agent.save
        flash[:token] = token.raw_token
        redirect_to @agent, notice: "Agent created. Copy the API token now — it won't be shown again."
      else
        token.destroy
        raise ActiveRecord::Rollback
      end
    end

    unless @agent.persisted?
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @stats = @agent.stats
    @server_url = request.base_url
  end

  def destroy
    @agent.api_token&.update!(active: false)
    @agent.destroy
    redirect_to agents_path, notice: "Agent deleted and API token revoked."
  end

  def download_config
    format_type = params[:format_type] || "claude_code"

    config = case format_type
    when "claude_code", "claude_desktop"
      { mcpServers: { "local-task" => { url: "#{request.base_url}/mcp/sse" } } }
    when "stdio"
      { mcpServers: { "local-task" => { command: "ruby", args: ["#{Rails.root}/bin/mcp_server"] } } }
    else
      { mcpServers: { "local-task" => { url: "#{request.base_url}/mcp/sse" } } }
    end

    filename = format_type == "claude_desktop" ? "claude_desktop_config.json" : ".mcp.json"

    send_data JSON.pretty_generate(config),
      filename: filename,
      type: "application/json",
      disposition: "attachment"
  end

  private

  def set_agent
    @agent = Current.user.agents.find(params[:id])
  end

  def agent_params
    params.require(:agent).permit(:name, :identifier, :description)
  end
end
