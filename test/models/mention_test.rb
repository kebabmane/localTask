require "test_helper"

class MentionTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid agent mention" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "agent",
      mention_text: "@claude-code",
      agent_identifier: "claude-code"
    )
    assert mention.valid?
  end

  test "valid task mention" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "task",
      mention_text: "LT-1",
      mentioned_task: tasks(:one)
    )
    assert mention.valid?
  end

  test "requires mention_type" do
    mention = Mention.new(
      comment: comments(:one),
      mention_text: "@claude-code",
      agent_identifier: "claude-code"
    )
    assert_not mention.valid?
    assert_includes mention.errors[:mention_type], "can't be blank"
  end

  test "mention_type must be agent or task" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "invalid",
      mention_text: "something"
    )
    assert_not mention.valid?
    assert_includes mention.errors[:mention_type], "is not included in the list"
  end

  test "requires mention_text" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "agent",
      agent_identifier: "claude-code"
    )
    assert_not mention.valid?
    assert_includes mention.errors[:mention_text], "can't be blank"
  end

  test "requires agent_identifier when mention_type is agent" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "agent",
      mention_text: "@agent"
    )
    assert_not mention.valid?
    assert_includes mention.errors[:agent_identifier], "can't be blank"
  end

  test "does not require agent_identifier when mention_type is task" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "task",
      mention_text: "LT-1",
      mentioned_task: tasks(:one)
    )
    assert mention.valid?
  end

  test "requires mentioned_task when mention_type is task" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "task",
      mention_text: "LT-1"
    )
    assert_not mention.valid?
    assert_includes mention.errors[:mentioned_task], "can't be blank"
  end

  test "does not require mentioned_task when mention_type is agent" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "agent",
      mention_text: "@claude-code",
      agent_identifier: "claude-code"
    )
    assert mention.valid?
  end

  # --- Associations ---

  test "belongs to comment" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "agent",
      mention_text: "@claude-code",
      agent_identifier: "claude-code"
    )
    assert_equal comments(:one), mention.comment
  end

  test "belongs to mentioned_task (optional)" do
    mention = Mention.new(
      comment: comments(:one),
      mention_type: "task",
      mention_text: "LT-1",
      mentioned_task: tasks(:one)
    )
    assert_equal tasks(:one), mention.mentioned_task
  end
end
