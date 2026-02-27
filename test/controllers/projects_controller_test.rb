require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    sign_in_as(@user)
  end

  # --- INDEX ---

  test "index redirects to root" do
    # projects#index has no template; the app uses root dashboard
    get root_path
    assert_response :success
  end

  test "index requires authentication" do
    sign_out
    get root_path
    assert_redirected_to new_session_path
  end

  # --- SHOW ---

  test "show redirects to board" do
    get project_path(@project)
    assert_redirected_to project_board_path(@project)
  end

  # --- NEW ---

  test "new renders form" do
    get new_project_path
    assert_response :success
  end

  # --- CREATE ---

  test "create project" do
    assert_difference "Project.count", 1 do
      post projects_path, params: {
        project: { name: "New Project", prefix: "NP", color: "#ff0000" }
      }
    end
    new_project = Project.last
    assert_redirected_to project_board_path(new_project)
    assert_equal "New Project", new_project.name
    assert_equal @user.id, new_project.user_id
  end

  test "create with invalid params renders new" do
    assert_no_difference "Project.count" do
      post projects_path, params: {
        project: { name: "", prefix: "", color: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- EDIT ---

  test "edit as owner" do
    get edit_project_path(@project)
    assert_response :success
  end

  test "edit as editor is forbidden" do
    sign_in_as(users(:two))
    get edit_project_path(@project)
    assert_response :redirect
  end

  # --- UPDATE ---

  test "update as owner" do
    patch project_path(@project), params: {
      project: { name: "Updated Name" }
    }
    assert_redirected_to project_board_path(@project)
    assert_equal "Updated Name", @project.reload.name
  end

  test "update as editor is forbidden" do
    sign_in_as(users(:two))
    patch project_path(@project), params: {
      project: { name: "Hacked" }
    }
    assert_response :redirect
    assert_not_equal "Hacked", @project.reload.name
  end

  # --- DESTROY ---

  test "destroy as owner" do
    # Create a fresh project with no tasks
    destroyable = @user.projects.create!(name: "Temp", prefix: "TMP", color: "#000000")
    assert_difference "Project.count", -1 do
      delete project_path(destroyable)
    end
    assert_redirected_to root_path
  end

  test "destroy as editor is forbidden" do
    sign_in_as(users(:two))
    assert_no_difference "Project.count" do
      delete project_path(@project)
    end
    assert_response :redirect
  end

  # --- AUTHORIZATION ---

  test "non-member cannot access project" do
    other_project = projects(:two)
    get project_path(other_project)
    assert_response :not_found
  end

  test "editor can view project show" do
    sign_in_as(users(:two))
    get project_path(@project)
    assert_redirected_to project_board_path(@project)
  end
end
