require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Redis cache store connects lazily, so it is safe during assets:precompile.
  config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Production should use external object storage (for example: amazon, google, azure).
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "amazon").to_sym
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info").to_sym
  config.log_tags = [:request_id]
  config.silence_healthcheck_path = "/health"

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_HOST", "smtp.sendgrid.net"),
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    domain: ENV.fetch("SMTP_DOMAIN", "yourdomain.com"),
    user_name: ENV.fetch("SMTP_USERNAME", "apikey"),
    password: ENV.fetch("SMTP_PASSWORD", nil),
    authentication: :plain,
    enable_starttls_auto: true
  }
  config.action_mailer.default_url_options = {
    host: ENV.fetch("ACTION_MAILER_DEFAULT_URL_HOST", "yourdomain.com"),
    protocol: "https"
  }
  Rails.application.routes.default_url_options[:host] = ENV.fetch("APP_HOST", "yourdomain.com")
  Rails.application.routes.default_url_options[:protocol] = "https"

  config.active_record.dump_schema_after_migration = false
  config.active_job.queue_adapter = :sidekiq

  allowed_hosts = ENV.fetch("ALLOWED_HOSTS", "yourdomain.com").split(",")
  config.hosts = allowed_hosts
end
