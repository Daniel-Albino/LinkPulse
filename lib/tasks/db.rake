# =============================================================================
# lib/tasks/db.rake
# Custom Rake tasks for database operations.
# =============================================================================

namespace :db do
  desc "Drop, recreate, migrate, and seed the database (useful in development)"
  task reset_and_seed: :environment do
    puts "== Running full DB reset =="
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
    puts "== Reset complete! =="
  end

  desc "Show migration status with timestamps"
  task migration_status: :environment do
    puts "\n== Migration Status ==\n\n"
    migrations = ActiveRecord::Base.connection.select_all(
      "SELECT version FROM schema_migrations ORDER BY version DESC"
    ).map { |r| r["version"] }

    ActiveRecord::MigrationContext.new(
      Rails.root.join("db/migrate"),
      ActiveRecord::SchemaMigration.new(ActiveRecord::Base.connection)
    ).migrations.each do |m|
      status = migrations.include?(m.version.to_s) ? "UP  " : "DOWN"
      puts "  #{status}  #{m.version}  #{m.name}"
    end
    puts ""
  end
end
