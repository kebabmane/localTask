require "test_helper"

class AgentWebhookTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid webhook with required attributes" do
    webhook = AgentWebhook.new(
      agent_identifier: "claude-code",
      url: "https://example.com/hook"
    )
    assert webhook.valid?
  end

  test "requires agent_identifier" do
    webhook = AgentWebhook.new(url: "https://example.com/hook")
    assert_not webhook.valid?
    assert_includes webhook.errors[:agent_identifier], "can't be blank"
  end

  test "requires url" do
    webhook = AgentWebhook.new(agent_identifier: "claude-code")
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "can't be blank"
  end

  test "url must be valid HTTP URL" do
    webhook = AgentWebhook.new(agent_identifier: "claude-code", url: "not-a-url")
    assert_not webhook.valid?
    assert_includes webhook.errors[:url], "must be a valid HTTP(S) URL"
  end

  test "url accepts https" do
    webhook = AgentWebhook.new(agent_identifier: "claude-code", url: "https://example.com/hook")
    assert webhook.valid?
  end

  test "url accepts http" do
    webhook = AgentWebhook.new(agent_identifier: "claude-code", url: "http://localhost:3000/hook")
    assert webhook.valid?
  end

  test "failures must be non-negative" do
    webhook = AgentWebhook.new(agent_identifier: "claude-code", url: "https://example.com/hook", failures: -1)
    assert_not webhook.valid?
    assert_includes webhook.errors[:failures], "must be greater than or equal to 0"
  end

  # --- Scopes ---

  test "active scope returns active webhooks" do
    assert_includes AgentWebhook.active, agent_webhooks(:one)
  end

  test "active scope excludes inactive webhooks" do
    agent_webhooks(:one).update!(active: false)
    assert_not_includes AgentWebhook.active, agent_webhooks(:one)
  end

  test "for_agent scope filters by agent_identifier" do
    results = AgentWebhook.for_agent("claude-code")
    assert_includes results, agent_webhooks(:one)
  end

  test "for_agent scope excludes other agents" do
    results = AgentWebhook.for_agent("other-agent")
    assert_not_includes results, agent_webhooks(:one)
  end

  # --- subscribes_to? ---

  test "subscribes_to? returns true when event_types is blank" do
    webhook = agent_webhooks(:one)
    # event_types is nil in fixture - subscribes to all
    assert webhook.subscribes_to?("task_assigned")
    assert webhook.subscribes_to?("status_changed")
    assert webhook.subscribes_to?("anything")
  end

  test "subscribes_to? returns true when event_type is in list" do
    webhook = agent_webhooks(:one)
    webhook.event_types = ["task_assigned", "status_changed"]
    assert webhook.subscribes_to?("task_assigned")
    assert webhook.subscribes_to?("status_changed")
  end

  test "subscribes_to? returns false when event_type is not in list" do
    webhook = agent_webhooks(:one)
    webhook.event_types = ["task_assigned"]
    assert_not webhook.subscribes_to?("status_changed")
  end

  # --- record_success! ---

  test "record_success! resets failures to zero" do
    webhook = agent_webhooks(:one)
    webhook.update!(failures: 5)

    webhook.record_success!

    assert_equal 0, webhook.reload.failures
  end

  test "record_success! sets last_delivered_at" do
    webhook = agent_webhooks(:one)
    assert_nil webhook.last_delivered_at

    webhook.record_success!

    assert_not_nil webhook.reload.last_delivered_at
  end

  # --- record_failure! ---

  test "record_failure! increments failure count" do
    webhook = agent_webhooks(:one)
    assert_equal 0, webhook.failures

    webhook.record_failure!

    assert_equal 1, webhook.reload.failures
  end

  test "record_failure! sets last_failed_at" do
    webhook = agent_webhooks(:one)
    assert_nil webhook.last_failed_at

    webhook.record_failure!

    assert_not_nil webhook.reload.last_failed_at
  end

  test "record_failure! keeps webhook active below MAX_FAILURES" do
    webhook = agent_webhooks(:one)
    webhook.update!(failures: 5)

    webhook.record_failure!

    assert webhook.reload.active
  end

  test "record_failure! deactivates webhook at MAX_FAILURES" do
    webhook = agent_webhooks(:one)
    webhook.update!(failures: AgentWebhook::MAX_FAILURES - 1)

    webhook.record_failure!

    assert_not webhook.reload.active
    assert_equal AgentWebhook::MAX_FAILURES, webhook.failures
  end

  test "MAX_FAILURES is 10" do
    assert_equal 10, AgentWebhook::MAX_FAILURES
  end

  test "record_failure! auto-deactivates after reaching threshold" do
    webhook = agent_webhooks(:one)

    # Simulate MAX_FAILURES consecutive failures
    AgentWebhook::MAX_FAILURES.times do
      webhook.record_failure!
    end

    webhook.reload
    assert_not webhook.active
    assert_equal AgentWebhook::MAX_FAILURES, webhook.failures
  end

  # --- Associations ---

  test "webhook fixture has expected attributes" do
    webhook = agent_webhooks(:one)
    assert_equal "claude-code", webhook.agent_identifier
    assert_equal "https://example.com/webhook", webhook.url
    assert webhook.active
    assert_equal 0, webhook.failures
  end
end
