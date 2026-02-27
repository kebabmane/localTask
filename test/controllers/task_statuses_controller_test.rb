require "test_helper"

class TaskStatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    sign_in_as(@user)
  end

  # --- CREATE ---

  test "create status as manager" do
    assert_difference "TaskStatus.count", 1 do
      post project_task_statuses_path(@project), params: {
        task_status: { name: "Review", color: "#ff9900", position: 4 }
      }
    end
    assert_redirected_to project_board_path(@project)
  end

  # --- UPDATE ---

  test "update status as manager" do
    status = task_statuses(:backlog)
    patch project_task_status_path(@project, status), params: {
      task_status: { name: "To Do" }
    }
    assert_redirected_to project_board_path(@project)
    assert_equal "To Do", status.reload.name
  end

  # --- DESTROY ---

  test "destroy status as manager" do
    # Create a status without tasks to safely destroy
    status = @project.task_statuses.create!(name: "Temp", color: "#000000", position: 99)
    assert_difference "TaskStatus.count", -1 do
      delete project_task_status_path(@project, status)
    end
    assert_redirected_to project_board_path(@project)
  end

  # --- AUTHORIZATION ---

  test "editor cannot create status" do
    sign_in_as(users(:two))
    assert_no_difference "TaskStatus.count" do
      post project_task_statuses_path(@project), params: {
        task_status: { name: "Hacked Status", color: "#ff0000" }
      }
    end
    assert_response :redirect
  end

  test "editor cannot update status" do
    sign_in_as(users(:two))
    status = task_statuses(:backlog)
    patch project_task_status_path(@project, status), params: {
      task_status: { name: "Hacked" }
    }
    assert_response :redirect
    assert_equal "Backlog", status.reload.name
  end

  test "editor cannot destroy status" do
    sign_in_as(users(:two))
    status = task_statuses(:backlog)
    assert_no_difference "TaskStatus.count" do
      delete project_task_status_path(@project, status)
    end
    assert_response :redirect
  end
end
