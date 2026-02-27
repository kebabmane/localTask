require "test_helper"

class TaskTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid task with required attributes" do
    task = Task.new(
      title: "New task",
      project: projects(:one),
      task_status: task_statuses(:backlog),
      creator: users(:one)
    )
    assert task.valid?
  end

  test "requires title" do
    task = Task.new(
      project: projects(:one),
      task_status: task_statuses(:backlog),
      creator: users(:one)
    )
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "task_number is unique within project scope" do
    task = Task.new(
      title: "Duplicate number",
      task_number: 1, # already taken by task :one
      project: projects(:one),
      task_status: task_statuses(:backlog),
      creator: users(:one)
    )
    assert_not task.valid?
    assert_includes task.errors[:task_number], "has already been taken"
  end

  test "task_number auto-assigned on create" do
    task = Task.create!(
      title: "Auto numbered",
      project: projects(:one),
      task_status: task_statuses(:backlog),
      creator: users(:one)
    )
    assert_equal 3, task.task_number # tasks 1 and 2 already exist
  end

  # --- Priority enum ---

  test "priority enum values" do
    assert_equal({ "low" => 0, "medium" => 1, "high" => 2, "critical" => 3 }, Task.priorities)
  end

  test "task one is high priority" do
    assert tasks(:one).high?
  end

  test "task two is medium priority" do
    assert tasks(:two).medium?
  end

  # --- display_id ---

  test "display_id returns PREFIX-NUMBER format" do
    task = tasks(:one)
    assert_equal "LT-1", task.display_id
  end

  test "display_id for second task" do
    task = tasks(:two)
    assert_equal "LT-2", task.display_id
  end

  # --- Soft delete ---

  test "soft_delete sets deleted_at" do
    task = tasks(:one)
    assert_nil task.deleted_at

    task.soft_delete(user: users(:one))

    assert_not_nil task.reload.deleted_at
    assert task.deleted?
  end

  test "soft_delete sets deleted_by_id when user provided" do
    task = tasks(:one)
    task.soft_delete(user: users(:one))
    assert_equal users(:one).id, task.deleted_by_id
  end

  test "soft_delete sets deleted_by_agent when agent provided" do
    task = tasks(:one)
    task.soft_delete(agent: "claude-code")
    assert_equal "claude-code", task.deleted_by_agent
  end

  test "soft deleted tasks are excluded by default scope" do
    task = tasks(:one)
    task.soft_delete(user: users(:one))

    assert_not_includes Task.all, task
  end

  test "restore! clears deleted_at and related fields" do
    task = tasks(:one)
    task.soft_delete(user: users(:one))
    assert task.deleted?

    task.restore!
    task.reload

    assert_nil task.deleted_at
    assert_nil task.deleted_by_id
    assert_nil task.deleted_by_agent
    assert_not task.deleted?
  end

  # --- Scopes ---

  test "with_deleted includes soft-deleted tasks" do
    task = tasks(:one)
    task.soft_delete(user: users(:one))

    assert_includes Task.with_deleted, task
  end

  test "only_deleted returns only soft-deleted tasks" do
    task = tasks(:one)
    task.soft_delete(user: users(:one))

    deleted_tasks = Task.only_deleted
    assert_includes deleted_tasks, task
    assert_not_includes deleted_tasks, tasks(:two)
  end

  test "open scope returns tasks with non-closed statuses" do
    open_tasks = Task.open
    assert_includes open_tasks, tasks(:one)  # backlog - not closed
    assert_includes open_tasks, tasks(:two)  # in_progress - not closed
  end

  test "closed scope returns tasks with closed statuses" do
    # Move task one to done status
    tasks(:one).update_columns(task_status_id: task_statuses(:done).id)
    closed_tasks = Task.closed
    assert_includes closed_tasks, tasks(:one)
  end

  test "by_agent scope filters by agent_identifier" do
    tasks(:one).update_columns(agent_identifier: "claude-code")
    assert_includes Task.by_agent("claude-code"), tasks(:one)
    assert_not_includes Task.by_agent("other-agent"), tasks(:one)
  end

  test "ordered scope orders by position ascending" do
    ordered = Task.ordered
    positions = ordered.pluck(:position)
    assert_equal positions.sort, positions
  end

  # --- blocked? ---

  test "blocked? returns true when dependency has open status" do
    task = tasks(:two) # depends on task :one which is in backlog (not closed)
    assert task.blocked?
  end

  test "blocked? returns false when dependency has closed status" do
    # Move the dependency (task one) to done (closed)
    tasks(:one).update_columns(task_status_id: task_statuses(:done).id)
    task = tasks(:two)
    assert_not task.blocked?
  end

  test "blocked? returns false when task has no dependencies" do
    task = tasks(:one) # no dependencies
    assert_not task.blocked?
  end

  # --- Associations ---

  test "belongs to project" do
    assert_equal projects(:one), tasks(:one).project
  end

  test "belongs to task_status" do
    assert_equal task_statuses(:backlog), tasks(:one).task_status
  end

  test "belongs to creator" do
    assert_equal users(:one), tasks(:one).creator
  end

  test "belongs to assignee (optional)" do
    assert_nil tasks(:one).assignee
    assert_equal users(:two), tasks(:two).assignee
  end

  test "has many comments" do
    assert_includes tasks(:one).comments, comments(:one)
  end

  test "has many task_dependencies" do
    assert_equal 1, tasks(:two).task_dependencies.count
  end

  test "has many dependencies through task_dependencies" do
    assert_includes tasks(:two).dependencies, tasks(:one)
  end
end
