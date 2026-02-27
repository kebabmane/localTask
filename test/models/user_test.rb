require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  # --- Associations ---

  test "has many sessions" do
    user = users(:one)
    assert_respond_to user, :sessions
    assert_kind_of Session, user.sessions.first
  end

  test "has many projects" do
    user = users(:one)
    assert_includes user.projects, projects(:one)
  end

  test "has many created_tasks" do
    user = users(:one)
    assert_includes user.created_tasks, tasks(:one)
    assert_includes user.created_tasks, tasks(:two)
  end

  test "has many assigned_tasks" do
    user = users(:two)
    assert_includes user.assigned_tasks, tasks(:two)
  end

  test "has many comments" do
    user = users(:one)
    assert_includes user.comments, comments(:one)
  end

  test "has many api_tokens" do
    user = users(:one)
    assert_includes user.api_tokens, api_tokens(:one)
  end

  test "has many agents" do
    user = users(:one)
    assert_includes user.agents, agents(:one)
  end

  test "has many project_memberships" do
    user = users(:two)
    assert_includes user.project_memberships, project_members(:editor_on_one)
  end

  test "has many shared_projects through project_memberships" do
    user = users(:two)
    assert_includes user.shared_projects, projects(:one)
  end

  # --- Validations ---

  test "requires email_address" do
    user = User.new(name: "Test", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires unique email_address" do
    user = User.new(name: "Duplicate", email_address: "one@example.com", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "requires valid email format" do
    user = User.new(name: "Test", email_address: "not-an-email", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end

  test "requires name" do
    user = User.new(email_address: "new@example.com", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  # --- Role enum ---

  test "role enum defaults to user" do
    user = users(:one)
    assert user.user?
  end

  test "role enum supports admin" do
    user = users(:one)
    user.admin!
    assert user.admin?
  end

  test "role enum defines user and admin" do
    assert_equal({ "user" => 0, "admin" => 1 }, User.roles)
  end

  # --- accessible_projects ---

  test "accessible_projects returns owned projects" do
    user = users(:one)
    accessible = user.accessible_projects
    assert_includes accessible, projects(:one)
  end

  test "accessible_projects returns shared projects" do
    user = users(:two)
    accessible = user.accessible_projects
    # User two owns project two and is an editor on project one
    assert_includes accessible, projects(:two)
    assert_includes accessible, projects(:one)
  end

  test "accessible_projects does not return unrelated projects" do
    user = users(:one)
    accessible = user.accessible_projects
    # User one does not have access to project two (not owner, not member)
    assert_not_includes accessible, projects(:two)
  end
end
