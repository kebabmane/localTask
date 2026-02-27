require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    @task = tasks(:one)
    @status = task_statuses(:backlog)
    sign_in_as(@user)
  end

  # --- SHOW ---

  test "show task as owner" do
    get project_task_path(@project, @task)
    assert_response :success
  end

  test "show task as editor" do
    sign_in_as(users(:two))
    get project_task_path(@project, @task)
    assert_response :success
  end

  # --- NEW ---

  test "new as owner" do
    get new_project_task_path(@project)
    assert_response :success
  end

  test "new as editor" do
    sign_in_as(users(:two))
    get new_project_task_path(@project)
    assert_response :success
  end

  # --- CREATE ---

  test "create task as owner" do
    assert_difference "Task.count", 1 do
      post project_tasks_path(@project), params: {
        task: { title: "New Task", priority: "medium", task_status_id: @status.id }
      }
    end
    assert_redirected_to project_board_path(@project)
  end

  test "create task as editor" do
    sign_in_as(users(:two))
    assert_difference "Task.count", 1 do
      post project_tasks_path(@project), params: {
        task: { title: "Editor Task", priority: "low", task_status_id: @status.id }
      }
    end
    assert_redirected_to project_board_path(@project)
  end

  test "create with invalid params renders new" do
    assert_no_difference "Task.count" do
      post project_tasks_path(@project), params: {
        task: { title: "", priority: "medium", task_status_id: @status.id }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- EDIT ---

  test "edit task as owner" do
    get edit_project_task_path(@project, @task)
    assert_response :success
  end

  # --- UPDATE ---

  test "update task as owner" do
    patch project_task_path(@project, @task), params: {
      task: { title: "Updated Title" }
    }
    assert_redirected_to project_task_path(@project, @task)
    assert_equal "Updated Title", @task.reload.title
  end

  test "update task as editor" do
    sign_in_as(users(:two))
    patch project_task_path(@project, @task), params: {
      task: { title: "Editor Updated" }
    }
    assert_redirected_to project_task_path(@project, @task)
    assert_equal "Editor Updated", @task.reload.title
  end

  # --- DESTROY (soft delete) ---

  test "destroy task soft deletes" do
    assert_no_difference "Task.with_deleted.count" do
      delete project_task_path(@project, @task)
    end
    assert_redirected_to project_board_path(@project)
    assert @task.reload.deleted?
  end

  # --- AUTHORIZATION ---

  test "non-member cannot access tasks" do
    other_project = projects(:two)
    get project_task_path(other_project, @task)
    assert_response :not_found
  end

  test "viewer cannot create tasks" do
    # Create a viewer membership for user two on project two
    user_two = users(:two)
    project_two = projects(:two)
    project_two.project_members.create!(user: @user, role: :viewer)
    sign_in_as(@user)

    two_backlog = task_statuses(:two_backlog)
    assert_no_difference "Task.count" do
      post project_tasks_path(project_two), params: {
        task: { title: "Should Fail", priority: "low", task_status_id: two_backlog.id }
      }
    end
    assert_response :redirect
  end
end
