require "test_helper"

class TaskStatusTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid task status" do
    status = TaskStatus.new(
      name: "Review",
      color: "#ff0000",
      position: 4,
      project: projects(:one)
    )
    assert status.valid?
  end

  test "requires name" do
    status = TaskStatus.new(color: "#ff0000", position: 4, project: projects(:one))
    assert_not status.valid?
    assert_includes status.errors[:name], "can't be blank"
  end

  test "name must be unique within project" do
    status = TaskStatus.new(
      name: "Backlog", # already exists in project one
      color: "#ff0000",
      position: 5,
      project: projects(:one)
    )
    assert_not status.valid?
    assert_includes status.errors[:name], "has already been taken"
  end

  test "same name allowed in different projects" do
    status = TaskStatus.new(
      name: "In Progress", # exists in project one but not project two
      color: "#ff0000",
      position: 2,
      project: projects(:two)
    )
    assert status.valid?
  end

  test "requires color" do
    status = TaskStatus.new(name: "Review", position: 4, project: projects(:one))
    status.color = nil
    assert_not status.valid?
    assert_includes status.errors[:color], "can't be blank"
  end

  # --- Scopes ---

  test "ordered scope returns statuses in position order" do
    statuses = projects(:one).task_statuses.ordered
    positions = statuses.pluck(:position)
    assert_equal positions.sort, positions
  end

  test "default_status scope returns statuses marked as default" do
    defaults = projects(:one).task_statuses.default_status
    assert_equal 1, defaults.count
    assert_equal task_statuses(:backlog), defaults.first
  end

  test "closed_statuses scope returns statuses marked as closed" do
    closed = projects(:one).task_statuses.closed_statuses
    assert_equal 1, closed.count
    assert_equal task_statuses(:done), closed.first
  end

  # --- Associations ---

  test "belongs to project" do
    assert_equal projects(:one), task_statuses(:backlog).project
  end

  test "has many tasks" do
    assert_includes task_statuses(:backlog).tasks, tasks(:one)
  end

  # --- Attributes ---

  test "is_default flag" do
    assert task_statuses(:backlog).is_default
    assert_not task_statuses(:in_progress).is_default
  end

  test "is_closed flag" do
    assert task_statuses(:done).is_closed
    assert_not task_statuses(:backlog).is_closed
  end
end
