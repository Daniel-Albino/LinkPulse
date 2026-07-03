# =============================================================================
# lib/tasks/docker.rake
# Common Docker operation Rake tasks.
# Run with: docker compose run --rm rails rails docker:<task>
# =============================================================================

namespace :docker do
  desc "Clean unused Docker images for this project"
  task :clean do
    puts "== Cleaning old Docker images =="
    system "docker image prune -f --filter label=app=link_pulse"
  end

  desc "Show current Docker environment info"
  task :info do
    puts "\n== Environment Info ==\n"
    puts "  Rails:      #{Rails.version}"
    puts "  Ruby:       #{RUBY_VERSION}"
    puts "  Environment: #{Rails.env}"
    puts "  DB URL:      #{ENV['DATABASE_URL'] || 'not set'}"
    puts "  Redis URL:   #{ENV['REDIS_URL'] || 'not set'}"
    puts ""
  end

  desc "Check PostgreSQL and Redis connectivity"
  task health: :environment do
    puts "\n== Health Check =="

    # PostgreSQL
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "  [OK] PostgreSQL - connected"
    rescue StandardError => e
      puts "  [FAIL] PostgreSQL - #{e.message}"
    end

    # Redis
    begin
      redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
      redis.ping
      puts "  [OK] Redis - connected"
    rescue StandardError => e
      puts "  [FAIL] Redis - #{e.message}"
    end

    puts ""
  end
end
