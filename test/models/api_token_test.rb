require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  FIXTURE_TOKEN = "test_token_value_for_fixtures_1234567890abcdefgh"

  # --- authenticate class method ---

  test "authenticate returns token for valid token string" do
    result = ApiToken.authenticate(FIXTURE_TOKEN)
    assert_not_nil result
    assert_equal api_tokens(:one), result
  end

  test "authenticate returns nil for invalid token" do
    result = ApiToken.authenticate("completely_wrong_token_value_that_does_not_exist")
    assert_nil result
  end

  test "authenticate returns nil for blank token" do
    assert_nil ApiToken.authenticate(nil)
    assert_nil ApiToken.authenticate("")
  end

  test "authenticate returns nil for inactive token" do
    api_tokens(:one).update!(active: false)
    result = ApiToken.authenticate(FIXTURE_TOKEN)
    assert_nil result
  end

  test "authenticate returns nil for expired token" do
    api_tokens(:one).update!(expires_at: 1.day.ago)
    result = ApiToken.authenticate(FIXTURE_TOKEN)
    assert_nil result
  end

  test "authenticate touches last_used_at" do
    assert_nil api_tokens(:one).last_used_at
    ApiToken.authenticate(FIXTURE_TOKEN)
    assert_not_nil api_tokens(:one).reload.last_used_at
  end

  test "authenticate matches by prefix then verifies digest" do
    # Token with correct prefix but wrong value should fail
    wrong_token = FIXTURE_TOKEN[0..7] + "wrong_remaining_value_here_padding"
    result = ApiToken.authenticate(wrong_token)
    assert_nil result
  end

  # --- expired? ---

  test "expired? returns false when expires_at is nil" do
    token = api_tokens(:one)
    assert_nil token.expires_at
    assert_not token.expired?
  end

  test "expired? returns true when expires_at is in the past" do
    token = api_tokens(:one)
    token.expires_at = 1.hour.ago
    assert token.expired?
  end

  test "expired? returns false when expires_at is in the future" do
    token = api_tokens(:one)
    token.expires_at = 1.hour.from_now
    assert_not token.expired?
  end

  # --- Token generation ---

  test "generates token on create" do
    token = ApiToken.create!(name: "New Token", user: users(:one))
    assert_not_nil token.raw_token
    assert_not_nil token.prefix
    assert_not_nil token.token_digest
    assert_equal token.raw_token[0..7], token.prefix
  end

  test "raw_token is 48 characters" do
    token = ApiToken.create!(name: "New Token", user: users(:one))
    assert_equal 48, token.raw_token.length
  end

  # --- Validations ---

  test "requires name" do
    token = ApiToken.new(user: users(:one))
    # generate_token runs before_validation, so token_digest will be set
    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  # --- Scopes ---

  test "active scope returns active non-expired tokens" do
    assert_includes ApiToken.active, api_tokens(:one)
  end

  test "active scope excludes inactive tokens" do
    api_tokens(:one).update!(active: false)
    assert_not_includes ApiToken.active, api_tokens(:one)
  end

  test "active scope excludes expired tokens" do
    api_tokens(:one).update!(expires_at: 1.day.ago)
    assert_not_includes ApiToken.active, api_tokens(:one)
  end

  # --- Associations ---

  test "belongs to user" do
    assert_equal users(:one), api_tokens(:one).user
  end

  test "has one agent" do
    assert_equal agents(:one), api_tokens(:one).agent
  end
end
