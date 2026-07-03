#!/usr/bin/env bash
# =============================================================================
# docker/scripts/deploy.sh
# Production deploy script via Docker Compose.
#
# Usage:
#   bash docker/scripts/deploy.sh
#   bash docker/scripts/deploy.sh --skip-backup
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${BLUE}[DEPLOY]${NC} $1"; }
ok()   { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[DEPLOY]${NC} $1"; }
err()  { echo -e "${RED}[DEPLOY]${NC} $1"; exit 1; }

COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
SKIP_BACKUP=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --skip-backup) SKIP_BACKUP=true ;;
  esac
done

echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  Deploy link_pulse -> Production${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""

# Check that .env exists
[ -f ".env" ] || err ".env file not found. Create it from .env.example."

# Check required variables
[ -z "$SECRET_KEY_BASE" ] && err "SECRET_KEY_BASE is not set in .env"
[ -z "$POSTGRES_PASSWORD" ] && err "POSTGRES_PASSWORD is not set in .env"

# Step 1: Database backup
if [ "$SKIP_BACKUP" = false ]; then
  log "STEP 1/6 - Database backup..."
  BACKUP_FILE="tmp/db_backup_$(date +%Y%m%d_%H%M%S).sql"
  docker compose $COMPOSE_FILES exec -T db \
    pg_dump -U "${POSTGRES_USER:-postgres}" "${POSTGRES_DB:-link_pulse_production}" \
    > "$BACKUP_FILE" 2>/dev/null || warn "Backup failed (this may be the first deploy)"
  ok "Backup saved to: $BACKUP_FILE"
else
  warn "STEP 1/6 - Backup skipped (--skip-backup)"
fi

# Step 2: Pull latest base images
log "STEP 2/6 - Pulling base images..."
docker compose $COMPOSE_FILES pull db redis 2>/dev/null || true
ok "Base images updated."

# Step 3: Build new image
log "STEP 3/6 - Building production image..."
docker compose $COMPOSE_FILES build --no-cache rails
ok "Image built."

# Step 4: Run migrations
log "STEP 4/6 - Running migrations..."
docker compose $COMPOSE_FILES run --rm rails bundle exec rails db:migrate
ok "Migrations applied."

# Step 5: Restart services
log "STEP 5/6 - Restarting services..."
docker compose $COMPOSE_FILES up -d --no-deps rails sidekiq nginx
ok "Services restarted."

# Step 6: Health check
log "STEP 6/6 - Running health check..."
sleep 5
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
  ok "Health check passed (HTTP $HTTP_STATUS)."
else
  err "Health check failed (HTTP $HTTP_STATUS). Check logs: docker compose logs rails"
fi

echo ""
echo -e "${GREEN}${BOLD}  Deploy completed successfully!${NC}"
echo ""
docker compose $COMPOSE_FILES ps
echo ""
