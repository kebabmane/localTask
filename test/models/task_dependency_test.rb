require "test_helper"

class TaskDependencyTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid task dependency" do
    # Create a new task to have a fresh dependency pair
    new_task = Task.create!(
      title: "New task for dependency",
      project: projects(:one),
      task_status: task_statuses(:backlog),
      creator: users(:one)
    )
    dep = TaskDependency.new(task: new_task, dependency: tasks(:two), dependency_type: :blocks)
    assert dep.valid?
  end

  test "uniqueness of dependency within task scope" do
    # Task two already depends on task one (fixture)
    duplicate = TaskDependency.new(
      task: tasks(:two),
      dependency: tasks(:one),
      dependency_type: :blocks
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:dependency_id], "has already been taken"
  end

  test "cannot depend on itself" do
    dep = TaskDependency.new(
      task: tasks(:one),
      dependency: tasks(:one),
      dependency_type: :blocks
    )
    assert_not dep.valid?
    assert dep.errors[:dependency].any? { |e| e.include?("cannot depend on itself") }
  end

  test "no circular dependency" do
    # Task two depends on task one (fixture).
    # Trying to make task one depend on task two should fail.
    circular = TaskDependency.new(
      task: tasks(:one),
      dependency: tasks(:two),
      dependency_type: :blocks
    )
    assert_not circular.valid?
    assert circular.errors[:dependency].any? { |e| e.include?("circular") }
  end

  # --- dependency_type enum ---

  test "dependency_type enum values" do
    assert_equal({ "blocks" => 0, "relates_to" => 1 }, TaskDependency.dependency_types)
  end

  test "fixture dependency is blocks type" do
    dep = task_dependencies(:one)
    assert dep.blocks?
  end

  test "relates_to dependency type" do
    new_task = Task.create!(
      title: "Related task",
      project: projects(:one),
      task_status: task_statuses(:backlog),
      creator: users(:one)
    )
    dep = TaskDependency.new(
      task: new_task,
      dependency: tasks(:one),
      dependency_type: :relates_to
    )
    assert dep.valid?
    assert dep.relates_to?
  end

  # --- Associations ---

  test "belongs to task" do
    dep = task_dependencies(:one)
    assert_equal tasks(:two), dep.task
  end

  test "belongs to dependency (which is a Task)" do
    dep = task_dependencies(:one)
    assert_equal tasks(:one), dep.dependency
  end

  # --- Fixture verification ---

  test "fixture: task two depends on task one" do
    dep = task_dependencies(:one)
    assert_equal tasks(:two).id, dep.task_id
    assert_equal tasks(:one).id, dep.dependency_id
    assert dep.blocks?
  end
end
