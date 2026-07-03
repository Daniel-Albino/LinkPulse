# =============================================================================
# spec/support/request_helpers.rb
# Helpers partilhados para request specs (API / controller tests).
# =============================================================================

module RequestHelpers
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  def json_headers
    { "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  # Authenticate a user for API tests
  # Adapt to your authentication system (Devise, has_secure_token, etc.)
  # def auth_headers(user)
  #   token = user.generate_token
  #   { "Authorization" => "Bearer #{token}" }.merge(json_headers)
  # end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
