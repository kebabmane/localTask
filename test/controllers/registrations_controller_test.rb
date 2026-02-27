require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  # --- NEW ---

  test "new renders registration form" do
    get new_registration_path
    assert_response :success
  end

  # --- CREATE ---

  test "create user" do
    assert_difference "User.count", 1 do
      post registration_path, params: {
        user: {
          name: "New User",
          email_address: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "create with validation errors" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          name: "",
          email_address: "invalid",
          password: "short",
          password_confirmation: "mismatch"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with duplicate email" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          name: "Duplicate",
          email_address: "one@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "does not require authentication" do
    # Should work without signing in
    get new_registration_path
    assert_response :success
  end
end
