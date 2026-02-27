require "test_helper"

class TaskPositionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    @task = tasks(:one)
    sign_in_as(@user)
  end

  test "update position as owner" do
    patch project_task_position_path(@project, @task), params: {
      task_status_id: task_statuses(:in_progress).id,
      position: 1
    }, as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @task.id, json["id"]
    assert_equal task_statuses(:in_progress).id, json["status_id"]
  end

  test "update position as editor" do
    sign_in_as(users(:two))
    patch project_task_position_path(@project, @task), params: {
      task_status_id: task_statuses(:backlog).id,
      position: 1
    }, as: :json
    assert_response :success
  end

  test "non-member cannot update position" do
    other_project = projects(:two)
    patch project_task_position_path(other_project, @task), params: {
      task_status_id: task_statuses(:backlog).id,
      position: 1
    }, as: :json
    assert_response :not_found
  end
end
