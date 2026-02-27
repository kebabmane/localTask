require "test_helper"

class ProjectMembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    @membership = project_members(:editor_on_one)
    sign_in_as(@user)
  end

  # --- INDEX ---

  test "index shows members as manager" do
    get project_members_path(@project)
    assert_response :success
  end

  # --- CREATE ---

  test "create member by email" do
    # Remove existing membership first to re-add
    new_user = User.create!(
      name: "New Member", email_address: "newmember@example.com",
      password: "password123", password_confirmation: "password123"
    )

    assert_difference "ProjectMember.count", 1 do
      post project_members_path(@project), params: {
        email_address: "newmember@example.com",
        role: "viewer"
      }
    end
    assert_redirected_to project_members_path(@project)
  end

  test "create with invalid email" do
    assert_no_difference "ProjectMember.count" do
      post project_members_path(@project), params: {
        email_address: "nonexistent@example.com",
        role: "viewer"
      }
    end
    assert_redirected_to project_members_path(@project)
    assert_equal "No user found with that email address.", flash[:alert]
  end

  test "create cannot add project owner as member" do
    assert_no_difference "ProjectMember.count" do
      post project_members_path(@project), params: {
        email_address: "one@example.com",
        role: "editor"
      }
    end
    assert_redirected_to project_members_path(@project)
    assert_equal "The project owner is already a member.", flash[:alert]
  end

  # --- DESTROY ---

  test "destroy member" do
    assert_difference "ProjectMember.count", -1 do
      delete project_member_path(@project, @membership)
    end
    assert_redirected_to project_members_path(@project)
  end

  # --- AUTHORIZATION ---

  test "editor cannot access members index" do
    sign_in_as(users(:two))
    get project_members_path(@project)
    assert_redirected_to root_path
  end

  test "editor cannot create member" do
    sign_in_as(users(:two))
    assert_no_difference "ProjectMember.count" do
      post project_members_path(@project), params: {
        email_address: "new@example.com",
        role: "viewer"
      }
    end
    assert_redirected_to root_path
  end

  test "editor cannot destroy member" do
    sign_in_as(users(:two))
    assert_no_difference "ProjectMember.count" do
      delete project_member_path(@project, @membership)
    end
    assert_redirected_to root_path
  end

  test "non-member cannot access members" do
    other_project = projects(:two)
    get project_members_path(other_project)
    assert_response :not_found
  end
end
