require "test_helper"

class Api::V1::AgentWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @webhook = agent_webhooks(:one)
  end

  # --- INDEX ---

  test "index returns webhooks scoped to users agents" do
    get api_v1_agent_webhooks_path, headers: api_headers
    assert_response :success
    webhooks = json_response
    assert_kind_of Array, webhooks
    assert webhooks.any? { |w| w["url"] == "https://example.com/webhook" }
  end

  test "index filters by agent" do
    get api_v1_agent_webhooks_path(agent: "claude-code"), headers: api_headers
    assert_response :success
    webhooks = json_response
    assert webhooks.all? { |w| w["agent_identifier"] == "claude-code" }
  end

  # --- CREATE ---

  test "create webhook for owned agent" do
    assert_difference "AgentWebhook.count", 1 do
      post api_v1_agent_webhooks_path, headers: api_headers, params: {
        webhook: {
          agent_identifier: "claude-code",
          url: "https://example.com/new-webhook",
          active: true,
          event_types: ["task_created"]
        }
      }.to_json
    end
    assert_response :created
    assert_equal "https://example.com/new-webhook", json_response["url"]
  end

  test "create webhook for unowned agent returns forbidden" do
    assert_no_difference "AgentWebhook.count" do
      post api_v1_agent_webhooks_path, headers: api_headers, params: {
        webhook: {
          agent_identifier: "nonexistent-agent",
          url: "https://example.com/bad-webhook",
          active: true
        }
      }.to_json
    end
    assert_response :forbidden
  end

  # --- UPDATE ---

  test "update webhook" do
    patch api_v1_agent_webhook_path(@webhook), headers: api_headers, params: {
      webhook: { url: "https://example.com/updated-webhook" }
    }.to_json
    assert_response :success
    assert_equal "https://example.com/updated-webhook", json_response["url"]
    assert_equal "https://example.com/updated-webhook", @webhook.reload.url
  end

  # --- DESTROY ---

  test "destroy webhook" do
    assert_difference "AgentWebhook.count", -1 do
      delete api_v1_agent_webhook_path(@webhook), headers: api_headers
    end
    assert_response :no_content
  end

  # --- AUTH ---

  test "requires authentication" do
    get api_v1_agent_webhooks_path
    assert_response :unauthorized
  end

  # --- SCOPING ---

  test "user cannot see webhooks for agents they dont own" do
    user_two = users(:two)
    token = user_two.api_tokens.create!(name: "User Two Token")

    get api_v1_agent_webhooks_path, headers: api_headers(token: token.raw_token)
    assert_response :success
    webhooks = json_response
    # User two has no agents, so they shouldn't see any webhooks
    assert_equal 0, webhooks.length
  end

  test "user cannot update webhook for agent they dont own" do
    user_two = users(:two)
    token = user_two.api_tokens.create!(name: "User Two Token")

    patch api_v1_agent_webhook_path(@webhook), headers: api_headers(token: token.raw_token), params: {
      webhook: { url: "https://evil.com/webhook" }
    }.to_json
    assert_response :not_found
  end
end
