# =============================================================================
# Silence health check logs to reduce noise in development and production.
# Health checks run frequently and don't need to be logged.
# =============================================================================

class SilentHealthCheckMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] == "/health"
      Rails.logger.silence { @app.call(env) }
    else
      @app.call(env)
    end
  end
end

Rails.application.config.middleware.insert_after(Rails::Rack::Logger, SilentHealthCheckMiddleware)
