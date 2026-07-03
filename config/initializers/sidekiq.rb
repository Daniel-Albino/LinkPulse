# =============================================================================
# config/initializers/sidekiq.rb
# Sidekiq 7+ configuration for background jobs.
# In v7, Redis config is set directly with REDIS_URL.
# =============================================================================

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
