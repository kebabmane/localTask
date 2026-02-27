require "test_helper"

class AgentTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid agent with required attributes" do
    agent = Agent.new(name: "Test Agent", user: users(:two))
    assert agent.valid?
  end

  test "requires name" do
    agent = Agent.new(user: users(:one))
    assert_not agent.valid?
    assert_includes agent.errors[:name], "can't be blank"
  end

  test "requires identifier" do
    agent = Agent.new(user: users(:one))
    # Name is also blank so generate_identifier won't set it
    assert_not agent.valid?
    assert_includes agent.errors[:identifier], "can't be blank"
  end

  test "identifier must be unique" do
    agent = Agent.new(name: "Claude Code", user: users(:two))
    agent.identifier = "claude-code" # already taken by fixture
    assert_not agent.valid?
    assert_includes agent.errors[:identifier], "has already been taken"
  end

  test "identifier format must start with lowercase letter" do
    agent = Agent.new(name: "Test", user: users(:two))
    agent.identifier = "1invalid"
    assert_not agent.valid?
    assert agent.errors[:identifier].any? { |e| e.include?("must start with a lowercase letter") }
  end

  test "identifier format rejects uppercase letters" do
    agent = Agent.new(name: "Test", user: users(:two))
    agent.identifier = "Invalid"
    assert_not agent.valid?
  end

  test "identifier format allows lowercase letters numbers hyphens and underscores" do
    agent = Agent.new(name: "Test", user: users(:two))
    agent.identifier = "my-agent_123"
    assert agent.valid?
  end

  # --- Auto-generation of identifier ---

  test "auto-generates identifier from name on create" do
    agent = Agent.new(name: "My Custom Agent", user: users(:two))
    agent.valid? # triggers before_validation
    assert_equal "my-custom-agent", agent.identifier
  end

  test "does not overwrite existing identifier" do
    agent = Agent.new(name: "My Agent", identifier: "custom-id", user: users(:two))
    agent.valid?
    assert_equal "custom-id", agent.identifier
  end

  test "parameterizes name with special characters" do
    agent = Agent.new(name: "Agent #1 (Test)", user: users(:two))
    agent.valid?
    assert_match(/\A[a-z][a-z0-9_-]*\z/, agent.identifier)
  end

  # --- stats method ---

  test "stats returns hash with correct keys" do
    agent = agents(:one)
    result = agent.stats
    assert_kind_of Hash, result
    assert_includes result.keys, :tasks_total
    assert_includes result.keys, :tasks_open
    assert_includes result.keys, :tasks_closed
    assert_includes result.keys, :webhooks_active
    assert_includes result.keys, :notifications_unread
    assert_includes result.keys, :comments_count
  end

  test "stats counts notifications for agent" do
    agent = agents(:one)
    stats = agent.stats
    # There is one unread notification for claude-code in fixtures
    assert_equal 1, stats[:notifications_unread]
  end

  test "stats counts active webhooks for agent" do
    agent = agents(:one)
    stats = agent.stats
    # There is one active webhook for claude-code in fixtures
    assert_equal 1, stats[:webhooks_active]
  end

  # --- Convenience accessors ---

  test "tasks returns tasks by agent identifier" do
    tasks(:one).update_columns(agent_identifier: "claude-code")
    agent = agents(:one)
    assert_includes agent.tasks, tasks(:one)
  end

  test "webhooks returns webhooks for agent" do
    agent = agents(:one)
    assert_includes agent.webhooks, agent_webhooks(:one)
  end

  test "notifications returns notifications for agent" do
    agent = agents(:one)
    assert_includes agent.notifications, agent_notifications(:one)
  end

  # --- Associations ---

  test "belongs to user" do
    assert_equal users(:one), agents(:one).user
  end

  test "belongs to api_token (optional)" do
    assert_equal api_tokens(:one), agents(:one).api_token
  end
end
