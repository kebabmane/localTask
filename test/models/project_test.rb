require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid project with all required attributes" do
    project = Project.new(
      name: "Test Project",
      prefix: "TST",
      color: "#ff0000",
      user: users(:one)
    )
    assert project.valid?
  end

  test "requires name" do
    project = Project.new(prefix: "TST", color: "#ff0000", user: users(:one))
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "requires prefix" do
    project = Project.new(name: "Test", color: "#ff0000", user: users(:one))
    assert_not project.valid?
    assert_includes project.errors[:prefix], "can't be blank"
  end

  test "requires unique prefix" do
    project = Project.new(name: "Duplicate", prefix: "LT", color: "#ff0000", user: users(:one))
    assert_not project.valid?
    assert_includes project.errors[:prefix], "has already been taken"
  end

  test "prefix must be uppercase letters and numbers only" do
    project = Project.new(name: "Test", prefix: "abc", color: "#ff0000", user: users(:one))
    assert_not project.valid?
    assert_includes project.errors[:prefix], "must be uppercase letters/numbers"
  end

  test "prefix must start with a letter" do
    project = Project.new(name: "Test", prefix: "1AB", color: "#ff0000", user: users(:one))
    assert_not project.valid?
    assert_includes project.errors[:prefix], "must be uppercase letters/numbers"
  end

  test "prefix max length is 5" do
    project = Project.new(name: "Test", prefix: "ABCDEF", color: "#ff0000", user: users(:one))
    assert_not project.valid?
    assert_includes project.errors[:prefix], "is too long (maximum is 5 characters)"
  end

  test "prefix allows uppercase letters and numbers" do
    project = Project.new(name: "Test", prefix: "AB1", color: "#ff0000", user: users(:one))
    assert project.valid?
  end

  test "requires color" do
    project = Project.new(name: "Test", prefix: "NCC", user: users(:one))
    project.color = nil
    assert_not project.valid?
    assert_includes project.errors[:color], "can't be blank"
  end

  # --- next_task_number ---

  test "next_task_number returns 1 for project with no tasks" do
    project = projects(:two)
    # Project two has no tasks in fixtures
    assert_equal 1, project.next_task_number
  end

  test "next_task_number returns max task_number plus 1" do
    project = projects(:one)
    # Project one has tasks with task_numbers 1 and 2
    assert_equal 3, project.next_task_number
  end

  # --- Authorization: can_view? ---

  test "can_view? returns true for project owner" do
    project = projects(:one)
    user = users(:one)
    assert project.can_view?(user)
  end

  test "can_view? returns true for editor member" do
    project = projects(:one)
    user = users(:two) # editor on project one
    assert project.can_view?(user)
  end

  test "can_view? returns true for viewer member" do
    # Create a viewer membership
    project = projects(:one)
    viewer = users(:two)
    project_members(:editor_on_one).update!(role: :viewer)
    assert project.can_view?(viewer)
  end

  test "can_view? returns false for non-member" do
    project = projects(:two) # owned by user two
    user = users(:one) # not a member
    assert_not project.can_view?(user)
  end

  # --- Authorization: can_edit? ---

  test "can_edit? returns true for project owner" do
    project = projects(:one)
    user = users(:one)
    assert project.can_edit?(user)
  end

  test "can_edit? returns true for editor member" do
    project = projects(:one)
    user = users(:two) # editor on project one
    assert project.can_edit?(user)
  end

  test "can_edit? returns false for viewer member" do
    project = projects(:one)
    viewer = users(:two)
    project_members(:editor_on_one).update!(role: :viewer)
    assert_not project.can_edit?(viewer)
  end

  # --- Authorization: can_manage? ---

  test "can_manage? returns true for project owner" do
    project = projects(:one)
    user = users(:one)
    assert project.can_manage?(user)
  end

  test "can_manage? returns false for non-owner" do
    project = projects(:one)
    user = users(:two) # editor, not owner
    assert_not project.can_manage?(user)
  end

  test "can_manage? returns true for member with owner role" do
    project = projects(:one)
    user = users(:two)
    project_members(:editor_on_one).update!(role: :owner)
    assert project.can_manage?(user)
  end

  # --- Scopes ---

  test "active scope excludes archived projects" do
    project = projects(:one)
    project.update!(archived: true)
    assert_not_includes Project.active, project
  end

  test "active scope includes non-archived projects" do
    assert_includes Project.active, projects(:one)
  end

  # --- Callbacks ---

  test "creates default statuses after creation" do
    project = Project.create!(
      name: "New Project",
      prefix: "NP",
      color: "#ff0000",
      user: users(:one)
    )
    assert_equal 6, project.task_statuses.count
    assert project.task_statuses.default_status.exists?
    assert project.task_statuses.closed_statuses.exists?
  end
end
