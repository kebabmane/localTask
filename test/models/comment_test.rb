require "test_helper"

class CommentTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid comment with required attributes" do
    comment = Comment.new(
      body: "A new comment",
      task: tasks(:one),
      user: users(:one)
    )
    assert comment.valid?
  end

  test "requires body" do
    comment = Comment.new(task: tasks(:one), user: users(:one))
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "body cannot be blank string" do
    comment = Comment.new(body: "", task: tasks(:one), user: users(:one))
    assert_not comment.valid?
  end

  # --- comment_type enum ---

  test "comment_type enum values" do
    assert_equal({ "comment" => 0, "status_change" => 1, "system" => 2 }, Comment.comment_types)
  end

  test "default comment_type is comment" do
    comment = comments(:one)
    assert comment.comment?
  end

  test "status_change comment type" do
    comment = Comment.new(
      body: "Status changed",
      task: tasks(:one),
      comment_type: :status_change
    )
    assert comment.status_change?
  end

  test "system comment type" do
    comment = Comment.new(
      body: "System message",
      task: tasks(:one),
      comment_type: :system
    )
    assert comment.system?
  end

  # --- author_name ---

  test "author_name returns user name when user is present" do
    comment = comments(:one)
    assert_equal "User One", comment.author_name
  end

  test "author_name returns titleized agent_identifier when agent present" do
    comment = Comment.new(
      body: "Agent comment",
      task: tasks(:one),
      agent_identifier: "claude-code"
    )
    assert_equal "Claude Code", comment.author_name
  end

  test "author_name returns System when no user and no agent" do
    comment = Comment.new(
      body: "System comment",
      task: tasks(:one),
      comment_type: :system
    )
    assert_equal "System", comment.author_name
  end

  # --- from_agent? ---

  test "from_agent? returns true when agent_identifier is present" do
    comment = Comment.new(
      body: "Agent comment",
      task: tasks(:one),
      agent_identifier: "claude-code"
    )
    assert comment.from_agent?
  end

  test "from_agent? returns false when agent_identifier is blank" do
    comment = comments(:one) # has user, no agent_identifier
    assert_not comment.from_agent?
  end

  # --- Associations ---

  test "belongs to task" do
    assert_equal tasks(:one), comments(:one).task
  end

  test "belongs to user (optional)" do
    comment = comments(:one)
    assert_equal users(:one), comment.user
  end

  test "has many mentions" do
    assert_respond_to comments(:one), :mentions
  end
end
