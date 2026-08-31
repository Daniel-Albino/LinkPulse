# =============================================================================
# Don't profile health check requests. Each profiled request writes
# mp_timers_* files to tmp/miniprofiler, which re-triggers the Tailwind
# watcher (css service) on every Docker healthcheck.
# =============================================================================

if defined?(Rack::MiniProfiler)
  Rack::MiniProfiler.config.skip_paths ||= []
  Rack::MiniProfiler.config.skip_paths << "/health"
end
