require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Cache
  config.cache_store = :null_store
  config.action_controller.perform_caching = false

  # Active Record
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Active Storage
  config.active_storage.service = :local

  # Mailer - Mailpit
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("MAIL_HOST", "mailpit"),
    port: ENV.fetch("MAIL_PORT", 1025).to_i
  }
  config.action_mailer.default_url_options = {
    host: ENV.fetch("ACTION_MAILER_DEFAULT_URL_HOST", "localhost:3000")
  }

  # Logs
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "debug").to_sym
  config.log_tags = [:request_id]

  # Active Job
  config.active_job.queue_adapter = :sidekiq

  # Hosts
  config.hosts << "localhost"
  config.hosts << "0.0.0.0"
  config.hosts << /.*\.ngrok\.io/
end
