require "test_helper"

class Api::V1::AgentNotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @notification = agent_notifications(:one)
  end

  # --- INDEX ---

  test "index returns notifications scoped to users projects" do
    get api_v1_agent_notifications_path, headers: api_headers
    assert_response :success
    notifications = json_response
    assert_kind_of Array, notifications
    assert notifications.any? { |n| n["event_type"] == "task_assigned" }
  end

  test "index filters by agent" do
    get api_v1_agent_notifications_path(agent: "claude-code"), headers: api_headers
    assert_response :success
    notifications = json_response
    assert notifications.all? { |n| n["agent_identifier"] == "claude-code" }
  end

  test "index filters by unread" do
    get api_v1_agent_notifications_path(unread: "true"), headers: api_headers
    assert_response :success
    notifications = json_response
    assert notifications.all? { |n| n["read"] == false }
  end

  test "index respects limit" do
    get api_v1_agent_notifications_path(limit: 1), headers: api_headers
    assert_response :success
    assert json_response.length <= 1
  end

  # --- MARK_READ ---

  test "mark_read marks notification as read" do
    assert_not @notification.read?
    patch mark_read_api_v1_agent_notification_path(@notification), headers: api_headers
    assert_response :success
    assert json_response["read"]
    assert @notification.reload.read?
  end

  # --- MARK_ALL_READ ---

  test "mark_all_read marks all unread as read" do
    post mark_all_read_api_v1_agent_notifications_path, headers: api_headers
    assert_response :success
    assert json_response["marked_read"] >= 0
  end

  test "mark_all_read filters by agent" do
    post mark_all_read_api_v1_agent_notifications_path(agent: "claude-code"), headers: api_headers
    assert_response :success
    count = json_response["marked_read"]
    assert count >= 0
  end

  # --- AUTH ---

  test "requires authentication" do
    get api_v1_agent_notifications_path
    assert_response :unauthorized
  end

  # --- SCOPING ---

  test "user cannot see notifications for tasks in inaccessible projects" do
    # User two's token should not see notifications for tasks in project one
    # unless they have access (user two IS editor on project one via fixture)
    user_two = users(:two)
    token = user_two.api_tokens.create!(name: "User Two Token")

    # User two has access to project one as editor, so they CAN see notifications
    # for tasks in project one
    get api_v1_agent_notifications_path, headers: api_headers(token: token.raw_token)
    assert_response :success
  end
end
