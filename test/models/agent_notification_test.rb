require "test_helper"

class AgentNotificationTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid notification with required attributes" do
    notification = AgentNotification.new(
      agent_identifier: "claude-code",
      event_type: "task_assigned",
      message: "A task was assigned",
      task: tasks(:one)
    )
    assert notification.valid?
  end

  test "requires agent_identifier" do
    notification = AgentNotification.new(
      event_type: "task_assigned",
      message: "A task was assigned",
      task: tasks(:one)
    )
    assert_not notification.valid?
    assert_includes notification.errors[:agent_identifier], "can't be blank"
  end

  test "requires event_type" do
    notification = AgentNotification.new(
      agent_identifier: "claude-code",
      message: "A task was assigned",
      task: tasks(:one)
    )
    assert_not notification.valid?
    assert_includes notification.errors[:event_type], "can't be blank"
  end

  test "event_type must be valid inclusion" do
    notification = AgentNotification.new(
      agent_identifier: "claude-code",
      event_type: "invalid_type",
      message: "Something happened",
      task: tasks(:one)
    )
    assert_not notification.valid?
    assert_includes notification.errors[:event_type], "is not included in the list"
  end

  test "event_type allows task_assigned" do
    notification = AgentNotification.new(
      agent_identifier: "claude-code",
      event_type: "task_assigned",
      message: "Assigned",
      task: tasks(:one)
    )
    assert notification.valid?
  end

  test "event_type allows status_changed" do
    notification = AgentNotification.new(
      agent_identifier: "claude-code",
      event_type: "status_changed",
      message: "Status changed",
      task: tasks(:one)
    )
    assert notification.valid?
  end

  test "event_type allows mentioned" do
    notification = AgentNotification.new(
      agent_identifier: "claude-code",
      event_type: "mentioned",
      message: "You were mentioned",
      task: tasks(:one)
    )
    assert notification.valid?
  end

  test "requires message" do
    notification = AgentNotification.new(
      agent_identifier: "claude-code",
      event_type: "task_assigned",
      task: tasks(:one)
    )
    assert_not notification.valid?
    assert_includes notification.errors[:message], "can't be blank"
  end

  # --- Scopes ---

  test "unread scope returns notifications where read is false" do
    unread = AgentNotification.unread
    assert_includes unread, agent_notifications(:one)
  end

  test "unread scope excludes read notifications" do
    agent_notifications(:one).update!(read: true, read_at: Time.current)
    assert_not_includes AgentNotification.unread, agent_notifications(:one)
  end

  test "for_agent scope filters by agent_identifier" do
    results = AgentNotification.for_agent("claude-code")
    assert_includes results, agent_notifications(:one)
  end

  test "for_agent scope excludes other agents" do
    results = AgentNotification.for_agent("other-agent")
    assert_not_includes results, agent_notifications(:one)
  end

  test "recent scope orders by created_at descending" do
    # Create another notification to verify ordering
    newer = AgentNotification.create!(
      agent_identifier: "claude-code",
      event_type: "status_changed",
      message: "Status changed on task",
      task: tasks(:two)
    )
    recent = AgentNotification.recent
    assert_equal newer, recent.first
  end

  # --- mark_as_read! ---

  test "mark_as_read! sets read to true" do
    notification = agent_notifications(:one)
    assert_not notification.read

    notification.mark_as_read!

    assert notification.reload.read
  end

  test "mark_as_read! sets read_at timestamp" do
    notification = agent_notifications(:one)
    assert_nil notification.read_at

    notification.mark_as_read!

    assert_not_nil notification.reload.read_at
  end

  # --- Associations ---

  test "belongs to task" do
    assert_equal tasks(:one), agent_notifications(:one).task
  end

  test "belongs to comment (optional)" do
    notification = agent_notifications(:one)
    assert_nil notification.comment
  end
end
