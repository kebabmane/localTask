require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = api_tokens(:one)
    sign_in_as(@user)
  end

  # --- INDEX ---

  test "index lists api tokens" do
    get api_tokens_path
    assert_response :success
  end

  # --- CREATE ---

  test "create api token" do
    assert_difference "ApiToken.count", 1 do
      post api_tokens_path, params: {
        api_token: { name: "My New Token" }
      }
    end
    assert_redirected_to api_tokens_path
    assert flash[:token].present?, "Expected raw token to be flashed"
  end

  test "create with invalid params" do
    assert_no_difference "ApiToken.count" do
      post api_tokens_path, params: {
        api_token: { name: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- DESTROY ---

  test "destroy api token" do
    assert_difference "ApiToken.count", -1 do
      delete api_token_path(@token)
    end
    assert_redirected_to api_tokens_path
  end

  test "cannot destroy another users token" do
    other_token = users(:two).api_tokens.create!(name: "Other Token")
    delete api_token_path(other_token)
    assert_response :not_found
  end

  # --- AUTH ---

  test "requires authentication" do
    sign_out
    get api_tokens_path
    assert_redirected_to new_session_path
  end
end
