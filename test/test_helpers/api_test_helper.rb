module ApiTestHelper
  API_TOKEN_VALUE = "test_token_value_for_fixtures_1234567890abcdefgh"

  def api_headers(token: API_TOKEN_VALUE, agent: nil)
    headers = {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
    headers["X-Agent-Identifier"] = agent if agent
    headers
  end

  def json_response
    JSON.parse(response.body)
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include ApiTestHelper
end
