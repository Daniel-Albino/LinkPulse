# =============================================================================
# app/controllers/application_controller.rb
# =============================================================================

class ApplicationController < ActionController::Base
  # CSRF protection
  protect_from_forgery with: :exception

  # Global security filters
  before_action :set_locale

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  # API helper - render JSON error response
  def respond_with_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
