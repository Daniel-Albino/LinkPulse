# =============================================================================
# app/controllers/health_controller.rb
# Health check endpoint for Docker and load balancers.
# GET /health -> 200 OK when all checks pass.
# =============================================================================

class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def show
    checks = { database: database_healthy?, redis: redis_healthy? }
    render json: { status: checks.values.all? ? "ok" : "error", checks: checks },
           status: checks.values.all? ? :ok : :service_unavailable
  end

  private

  def database_healthy?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def redis_healthy?
    Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")).ping == "PONG"
  rescue StandardError
    false
  end
end
