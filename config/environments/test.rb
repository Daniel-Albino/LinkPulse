require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=3600" }
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  config.active_record.maintain_test_schema = true
  config.active_job.queue_adapter = :test
  config.log_level = :warn
end
