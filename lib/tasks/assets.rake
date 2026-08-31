# =============================================================================
# lib/tasks/assets.rake
# Guard against running `assets:precompile` in development.
#
# A dev precompile writes public/assets/.manifest.json, which flips Propshaft
# to its static resolver and freezes CSS/JS digests until the container is
# restarted (breaking live reload). Precompilation belongs to the production
# image build only (see Dockerfile). Override intentionally with
# FORCE_PRECOMPILE=1.
# =============================================================================

namespace :assets do
  task :refuse_in_development do
    if Rails.env.development? && ENV["FORCE_PRECOMPILE"] != "1"
      abort <<~MSG
        [assets:precompile] Refusing to run in development.

        Precompiling here writes public/assets/.manifest.json, which switches
        Propshaft to its static resolver and freezes your CSS/JS until the
        container restarts.

          - To test precompilation, build the production image instead
            (the Dockerfile 'assets' stage runs the real precompile).
          - To force it here anyway, re-run with FORCE_PRECOMPILE=1.
      MSG
    end
  end
end

# Run the guard before precompile. Declared as a prerequisite (not an enhance
# block) so it fires *before* any compilation, and so Rake merges it onto the
# task regardless of load order.
task "assets:precompile" => "assets:refuse_in_development"
