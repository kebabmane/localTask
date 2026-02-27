require "test_helper"

class AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @agent = agents(:one)
    sign_in_as(@user)
  end

  # --- INDEX ---

  test "index lists agents" do
    get agents_path
    assert_response :success
  end

  # --- NEW ---

  test "new renders form" do
    get new_agent_path
    assert_response :success
  end

  # --- CREATE ---

  test "create agent auto-creates api token" do
    assert_difference ["Agent.count", "ApiToken.count"], 1 do
      post agents_path, params: {
        agent: { name: "New Agent", identifier: "new-agent", description: "Test" }
      }
    end
    agent = Agent.last
    assert_redirected_to agent_path(agent)
    assert flash[:token].present?, "Expected raw token to be flashed"
    assert agent.api_token.present?
  end

  test "create with invalid params renders new" do
    assert_no_difference "Agent.count" do
      post agents_path, params: {
        agent: { name: "", identifier: "", description: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- SHOW ---

  test "show agent" do
    get agent_path(@agent)
    assert_response :success
  end

  test "cannot show another users agent" do
    other_user = users(:two)
    other_agent = other_user.agents.create!(
      name: "Other Agent", identifier: "other-agent",
      api_token: other_user.api_tokens.create!(name: "Other Token")
    )
    get agent_path(other_agent)
    assert_response :not_found
  end

  # --- DESTROY ---

  test "destroy agent revokes token" do
    token = @agent.api_token
    assert_difference "Agent.count", -1 do
      delete agent_path(@agent)
    end
    assert_redirected_to agents_path
    assert_not token.reload.active?, "Expected API token to be deactivated"
  end

  # --- DOWNLOAD_CONFIG ---

  test "download config claude_code format" do
    get download_config_agent_path(@agent, format_type: "claude_code")
    assert_response :success
    assert_equal "application/json", response.content_type
    json = JSON.parse(response.body)
    assert json["mcpServers"]["local-task"]["url"].present?
  end

  test "download config claude_desktop format" do
    get download_config_agent_path(@agent, format_type: "claude_desktop")
    assert_response :success
    assert response.headers["Content-Disposition"].include?("claude_desktop_config.json")
  end

  test "download config stdio format" do
    get download_config_agent_path(@agent, format_type: "stdio")
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ruby", json["mcpServers"]["local-task"]["command"]
  end

  # --- AUTH ---

  test "requires authentication" do
    sign_out
    get agents_path
    assert_redirected_to new_session_path
  end
end
