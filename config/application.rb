require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module LinkPulse
  class Application < Rails::Application
    config.load_defaults 8.1

    config.time_zone = "Lisbon"
    config.active_record.default_timezone = :utc

    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en]
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    config.active_job.queue_adapter = :sidekiq

    config.filter_parameters += %i[
      passw secret token _key crypt salt certificate
      otp ssn cvv cvc credit_card
    ]
  end
end
