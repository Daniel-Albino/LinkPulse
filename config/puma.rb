# =============================================================================
# config/puma.rb
# Puma server configuration.
# Single mode in development; clustered in production via WEB_CONCURRENCY.
# =============================================================================

# Thread count per worker
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Workers in production (separate processes)
worker_count = ENV.fetch("WEB_CONCURRENCY", 2).to_i
if worker_count > 1 && !ENV["RAILS_ENV"].to_s.start_with?("development")
  workers worker_count

  # Preload app for copy-on-write memory savings with multiple workers.
  # Rails 8 handles reconnecting Active Record after fork automatically.
  preload_app!
end

# Port
port ENV.fetch("PORT", 3000)

# Environment
environment ENV.fetch("RAILS_ENV", "development")

# PID file
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Allow `rails restart` to restart Puma
plugin :tmp_restart
