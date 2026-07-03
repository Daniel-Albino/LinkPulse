#!/usr/bin/env bash
# =============================================================================
# docker/entrypoints/entrypoint.sh
# Main Rails container entrypoint. Runs every time the container starts.
#
# Database setup is fully idempotent: `rails db:prepare` creates the database
# if it does not exist, loads the schema on first boot, and runs pending
# migrations on subsequent boots. No marker files needed.
#
# Environment knobs:
#   SKIP_DB_PREPARE=true   - skip database preparation (e.g. sidekiq container)
#   DB_WAIT_MAX_ATTEMPTS   - max attempts waiting for PostgreSQL (default: 30)
#   DB_WAIT_SECONDS        - seconds between attempts (default: 2)
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

APP_HOME=${APP_HOME:-/app}
cd "${APP_HOME}"

# =============================================================================
# STEP 1 - Gems
# In production the image already ships all gems (bundle check is a no-op).
# In development (source mounted as a volume) install anything missing.
# =============================================================================
log_info "Checking gems..."
if ! bundle check > /dev/null 2>&1; then
  log_warning "Gems missing. Running bundle install..."
  bundle install --jobs="${BUNDLE_JOBS:-4}" --retry="${BUNDLE_RETRY:-3}"
fi
log_success "Gems ready."

# =============================================================================
# STEP 2 - Remove stale server.pid (prevents restart crash)
# =============================================================================
PID_FILE="${APP_HOME}/tmp/pids/server.pid"
if [ -f "${PID_FILE}" ]; then
  log_warning "Stale server.pid found. Removing..."
  rm -f "${PID_FILE}"
fi

# =============================================================================
# STEP 3 - Database preparation (idempotent)
# =============================================================================
wait_for_db() {
  local host="${POSTGRES_HOST:-db}"
  local port="${POSTGRES_PORT:-5432}"
  local user="${POSTGRES_USER:-postgres}"
  local max_attempts="${DB_WAIT_MAX_ATTEMPTS:-30}"
  local wait_seconds="${DB_WAIT_SECONDS:-2}"
  local attempt=0

  log_info "Waiting for PostgreSQL at ${host}:${port}..."
  until pg_isready -h "${host}" -p "${port}" -U "${user}" -q; do
    attempt=$((attempt + 1))
    if [ "${attempt}" -ge "${max_attempts}" ]; then
      log_error "PostgreSQL not available after ${max_attempts} attempts. Aborting."
      exit 1
    fi
    sleep "${wait_seconds}"
  done
  log_success "PostgreSQL available."
}

if [ "${SKIP_DB_PREPARE:-false}" != "true" ]; then
  wait_for_db

  # db:prepare does the right thing in every scenario:
  #   - database missing        -> create + load schema + seed
  #   - schema not loaded       -> load schema
  #   - pending migrations      -> migrate
  #   - everything up to date   -> no-op
  log_info "Preparing database (rails db:prepare)..."
  if bundle exec rails db:prepare; then
    log_success "Database ready."
  else
    log_error "Database preparation failed. Check the output above."
    exit 1
  fi
else
  log_info "SKIP_DB_PREPARE=true - skipping database preparation."
fi

# =============================================================================
# STEP 4 - Run the container command
# =============================================================================
log_success "Container ready. Starting: $*"
echo ""
exec "$@"
