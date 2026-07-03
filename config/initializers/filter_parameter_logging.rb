# =============================================================================
# config/initializers/filter_parameter_logging.rb
# Filter sensitive parameters from Rails logs.
# =============================================================================

Rails.application.config.filter_parameters += %i[
  passw
  password
  password_confirmation
  secret
  token
  _key
  crypt
  salt
  certificate
  otp
  ssn
  cvv
  cvc
  credit_card
  card_number
  access_token
  refresh_token
  api_key
  secret_key
]
