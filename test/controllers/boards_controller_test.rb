require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    sign_in_as(@user)
  end

  test "show board as owner" do
    get project_board_path(@project)
    assert_response :success
  end

  test "show board as editor" do
    sign_in_as(users(:two))
    get project_board_path(@project)
    assert_response :success
  end

  test "non-member cannot view board" do
    other_project = projects(:two)
    get project_board_path(other_project)
    assert_response :not_found
  end

  test "requires authentication" do
    sign_out
    get project_board_path(@project)
    assert_redirected_to new_session_path
  end
end
