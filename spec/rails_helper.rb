# =============================================================================
# spec/rails_helper.rb
# RSpec configuration for Rails.
# =============================================================================

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
abort("Running tests in production!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"
require "shoulda/matchers"
require "database_cleaner/active_record"

# Carrega support files
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Check pending migrations
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = ["#{Rails.root}/spec/fixtures"]
  config.use_transactional_fixtures = false # Gerido pelo DatabaseCleaner
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

# FactoryBot, DatabaseCleaner and Shoulda Matchers are configured in
# spec/support/*.rb, which is loaded above. Do not duplicate them here:
# a second `around(:each) { DatabaseCleaner.cleaning }` would nest cleaning
# blocks around every example.
