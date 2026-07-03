#!/usr/bin/env bash
# =============================================================================
# docker/scripts/ci-test.sh
# Run CI test suite (GitHub Actions, GitLab CI, etc.)
#
# Usage (via docker compose):
#   docker compose run --rm -e RAILS_ENV=test rails bash docker/scripts/ci-test.sh
# =============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[CI]${NC} $1"; }
ok()  { echo -e "${GREEN}[CI]${NC} $1"; }
err() { echo -e "${RED}[CI]${NC} $1"; exit 1; }

export RAILS_ENV=test

log "== Starting CI test suite =="

# Wait for DB
log "Waiting for database..."
bash docker/scripts/wait-for-db.sh

# Install gems
log "Checking gems..."
bundle check || bundle install --jobs=4 --retry=3

# Prepare test database
log "Preparing test database..."
bundle exec rails db:prepare

# Linting with RuboCop
log "Running RuboCop..."
bundle exec rubocop --no-color --format progress || err "RuboCop failed."
ok "RuboCop passed."

# Security analysis with Brakeman
log "Running Brakeman..."
bundle exec brakeman --no-progress --quiet || err "Brakeman found vulnerabilities."
ok "Brakeman passed."

# RSpec test suite
log "Running RSpec..."
bundle exec rspec --format progress --format json --out tmp/rspec_results.json
ok "RSpec passed."

log "== All checks passed successfully! =="
