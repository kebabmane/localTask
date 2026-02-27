require "test_helper"

class ProjectMemberTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid project member" do
    # User one is not yet a member of project two
    member = ProjectMember.new(project: projects(:two), user: users(:one), role: :editor)
    assert member.valid?
  end

  test "requires role" do
    member = ProjectMember.new(project: projects(:two), user: users(:one))
    member.role = nil
    assert_not member.valid?
    assert_includes member.errors[:role], "can't be blank"
  end

  test "enforces uniqueness of user per project" do
    # User two is already an editor on project one
    duplicate = ProjectMember.new(project: projects(:one), user: users(:two), role: :viewer)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "is already a member of this project"
  end

  test "allows same user on different projects" do
    member = ProjectMember.new(project: projects(:two), user: users(:one), role: :viewer)
    assert member.valid?
  end

  # --- Role enum ---

  test "role enum defines viewer, editor, and owner" do
    assert_equal({ "viewer" => 0, "editor" => 1, "owner" => 2 }, ProjectMember.roles)
  end

  test "viewer role" do
    member = project_members(:editor_on_one)
    member.viewer!
    assert member.viewer?
    assert_not member.editor?
  end

  test "editor role" do
    member = project_members(:editor_on_one)
    assert member.editor?
  end

  test "owner role" do
    member = project_members(:editor_on_one)
    member.owner!
    assert member.owner?
  end

  # --- Associations ---

  test "belongs to project" do
    member = project_members(:editor_on_one)
    assert_equal projects(:one), member.project
  end

  test "belongs to user" do
    member = project_members(:editor_on_one)
    assert_equal users(:two), member.user
  end
end
