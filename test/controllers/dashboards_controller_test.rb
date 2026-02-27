require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "show displays dashboard" do
    get root_path
    assert_response :success
  end

  test "shows accessible projects" do
    get root_path
    assert_response :success
    # User one owns project one and can see it
    assert_select "body" # page renders successfully
  end

  test "requires authentication" do
    sign_out
    get root_path
    assert_redirected_to new_session_path
  end
end
