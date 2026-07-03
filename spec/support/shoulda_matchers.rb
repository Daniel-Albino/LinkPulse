# =============================================================================
# spec/support/shoulda_matchers.rb
# Configura Shoulda Matchers para RSpec + Rails.
# =============================================================================

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
