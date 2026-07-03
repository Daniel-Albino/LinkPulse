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

  # Factory Bot
  config.include FactoryBot::Syntax::Methods

  # Database Cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  # Para specs com JS (Capybara), usa truncation
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each, js: true) do
    DatabaseCleaner.strategy = :transaction
  end
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
