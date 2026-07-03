# =============================================================================
# spec/support/database_cleaner.rb
# Ensure the database is clean between tests.
# =============================================================================

# Inside Docker the database host is "db", which DatabaseCleaner's safeguard
# treats as a remote URL. The test database name check still protects us.
DatabaseCleaner.allow_remote_database_url = true

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  # JS specs use truncation (Capybara JS drivers do not support transactions)
  config.before(:each, :js) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each, :js) do
    DatabaseCleaner.strategy = :transaction
  end
end
