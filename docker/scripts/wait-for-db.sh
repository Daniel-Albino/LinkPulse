#!/usr/bin/env bash
# =============================================================================
# docker/scripts/wait-for-db.sh
# Wait until PostgreSQL is ready before continuing.
# Useful in CI/CD or migration scripts.
#
# Usage:
#   bash docker/scripts/wait-for-db.sh
#   bash docker/scripts/wait-for-db.sh && bundle exec rails db:migrate
# =============================================================================

set -e

HOST="${POSTGRES_HOST:-db}"
PORT="${POSTGRES_PORT:-5432}"
USER="${POSTGRES_USER:-postgres}"
MAX_ATTEMPTS="${DB_WAIT_MAX_ATTEMPTS:-30}"
WAIT_SECONDS="${DB_WAIT_SECONDS:-2}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}[wait-for-db]${NC} Waiting for PostgreSQL at ${HOST}:${PORT}..."

attempt=0
until pg_isready -h "${HOST}" -p "${PORT}" -U "${USER}" -q; do
  attempt=$((attempt + 1))
  if [ "${attempt}" -ge "${MAX_ATTEMPTS}" ]; then
    echo -e "${RED}[wait-for-db]${NC} PostgreSQL unavailable after ${MAX_ATTEMPTS} attempts. Exiting."
    exit 1
  fi
  echo -e "${YELLOW}[wait-for-db]${NC} Attempt ${attempt}/${MAX_ATTEMPTS}. Waiting ${WAIT_SECONDS}s..."
  sleep "${WAIT_SECONDS}"
done

echo -e "${GREEN}[wait-for-db]${NC} PostgreSQL is available!"
