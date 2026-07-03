# =============================================================================
# app/jobs/application_job.rb
# =============================================================================

class ApplicationJob < ActiveJob::Base
  # Automatically retry on deadlock errors
  retry_on ActiveRecord::Deadlocked

  # Discard jobs with records that no longer exist
  discard_on ActiveJob::DeserializationError

  # Default timeout
  # queue_as :default
end
