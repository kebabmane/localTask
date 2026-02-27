require "test_helper"

class Api::V1::TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    @task = tasks(:one)
    @status = task_statuses(:backlog)
  end

  # --- INDEX ---

  test "index returns tasks" do
    get api_v1_project_tasks_path(@project), headers: api_headers
    assert_response :success
    tasks = json_response
    assert_kind_of Array, tasks
    assert tasks.any? { |t| t["title"] == "Fix login bug" }
  end

  test "index filters by status" do
    get api_v1_project_tasks_path(@project, status_id: @status.id), headers: api_headers
    assert_response :success
    tasks = json_response
    assert tasks.all? { |t| t["status"]["id"] == @status.id }
  end

  test "index filters by priority" do
    get api_v1_project_tasks_path(@project, priority: "high"), headers: api_headers
    assert_response :success
    tasks = json_response
    assert tasks.all? { |t| t["priority"] == "high" }
  end

  test "index for inaccessible project returns not found" do
    get api_v1_project_tasks_path(projects(:two)), headers: api_headers
    assert_response :not_found
  end

  # --- SHOW ---

  test "show returns task details" do
    get api_v1_project_task_path(@project, @task), headers: api_headers
    assert_response :success
    assert_equal "Fix login bug", json_response["title"]
  end

  test "show returns not found for nonexistent task" do
    get api_v1_project_task_path(@project, id: 999999), headers: api_headers
    assert_response :not_found
  end

  # --- CREATE ---

  test "create task" do
    assert_difference "Task.count", 1 do
      post api_v1_project_tasks_path(@project), headers: api_headers, params: {
        task: { title: "API Task", priority: "medium", task_status_id: @status.id }
      }.to_json
    end
    assert_response :created
    assert_equal "API Task", json_response["title"]
  end

  test "create task with agent headers" do
    assert_difference "Task.count", 1 do
      post api_v1_project_tasks_path(@project),
        headers: api_headers(agent: "claude-code"),
        params: {
          task: { title: "Agent Task", priority: "low", task_status_id: @status.id }
        }.to_json
    end
    assert_response :created
    assert_equal "claude-code", Task.last.agent_identifier
  end

  test "create with invalid params" do
    assert_no_difference "Task.count" do
      post api_v1_project_tasks_path(@project), headers: api_headers, params: {
        task: { title: "", priority: "medium", task_status_id: @status.id }
      }.to_json
    end
    assert_response :unprocessable_entity
  end

  # --- UPDATE ---

  test "update task" do
    patch api_v1_project_task_path(@project, @task), headers: api_headers, params: {
      task: { title: "Updated via API" }
    }.to_json
    assert_response :success
    assert_equal "Updated via API", json_response["title"]
    assert_equal "Updated via API", @task.reload.title
  end

  test "update task with agent headers" do
    patch api_v1_project_task_path(@project, @task),
      headers: api_headers(agent: "claude-code"),
      params: {
        task: { title: "Agent Updated" }
      }.to_json
    assert_response :success
    assert_equal "claude-code", @task.reload.agent_identifier
  end

  # --- DESTROY ---

  test "destroy soft deletes task" do
    assert_no_difference "Task.with_deleted.count" do
      delete api_v1_project_task_path(@project, @task), headers: api_headers
    end
    assert_response :no_content
    assert @task.reload.deleted?
  end

  # --- AUTH ---

  test "requires authentication" do
    get api_v1_project_tasks_path(@project)
    assert_response :unauthorized
  end
end
