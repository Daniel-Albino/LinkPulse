# =============================================================================
# app/mailers/application_mailer.rb
# =============================================================================

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "noreply@link_pulse.com")
  layout "mailer"
end
