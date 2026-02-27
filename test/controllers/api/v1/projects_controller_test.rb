require "test_helper"

class Api::V1::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
  end

  # --- INDEX ---

  test "index returns accessible projects" do
    get api_v1_projects_path, headers: api_headers
    assert_response :success
    projects = json_response
    assert_kind_of Array, projects
    assert projects.any? { |p| p["name"] == "Project One" }
  end

  test "index requires authentication" do
    get api_v1_projects_path
    assert_response :unauthorized
  end

  test "index with invalid token" do
    get api_v1_projects_path, headers: api_headers(token: "invalid_token")
    assert_response :unauthorized
  end

  # --- SHOW ---

  test "show returns project details" do
    get api_v1_project_path(@project), headers: api_headers
    assert_response :success
    assert_equal "Project One", json_response["name"]
  end

  test "show returns not found for inaccessible project" do
    other_project = projects(:two)
    get api_v1_project_path(other_project), headers: api_headers
    assert_response :not_found
  end

  # --- CREATE ---

  test "create project" do
    assert_difference "Project.count", 1 do
      post api_v1_projects_path, headers: api_headers, params: {
        project: { name: "API Project", prefix: "AP", color: "#00ff00" }
      }.to_json
    end
    assert_response :created
    assert_equal "API Project", json_response["name"]
  end

  test "create with invalid params returns errors" do
    assert_no_difference "Project.count" do
      post api_v1_projects_path, headers: api_headers, params: {
        project: { name: "", prefix: "", color: "" }
      }.to_json
    end
    assert_response :unprocessable_entity
  end

  # --- UPDATE ---

  test "update as owner" do
    patch api_v1_project_path(@project), headers: api_headers, params: {
      project: { name: "Updated via API" }
    }.to_json
    assert_response :success
    assert_equal "Updated via API", json_response["name"]
    assert_equal "Updated via API", @project.reload.name
  end

  test "update as non-manager returns forbidden" do
    # User two is editor on project one, not manager
    # We need user two's token for this
    user_two = users(:two)
    token = user_two.api_tokens.create!(name: "User Two Token")

    patch api_v1_project_path(@project), headers: api_headers(token: token.raw_token), params: {
      project: { name: "Should Not Work" }
    }.to_json
    assert_response :forbidden
    assert_not_equal "Should Not Work", @project.reload.name
  end

  test "update inaccessible project returns not found" do
    other_project = projects(:two)
    patch api_v1_project_path(other_project), headers: api_headers, params: {
      project: { name: "Hacked" }
    }.to_json
    assert_response :not_found
  end
end
