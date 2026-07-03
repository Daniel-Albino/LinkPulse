#!/usr/bin/env bash
# =============================================================================
# scripts/rename_project.sh
# Rename the template project to a new name.
#
# The current name is auto-detected from config/application.rb, so the script
# works no matter how many times the project has been renamed.
#
# Usage:
#   bash scripts/rename_project.sh new_project_name
#   bash scripts/rename_project.sh new_project_name --yes      # no confirmation
#   bash scripts/rename_project.sh new_project_name --dry-run  # preview only
#
# Example:
#   bash scripts/rename_project.sh awesome_saas
#
# What it does:
#   1. Detects the current project name (snake_case, CamelCase, human)
#   2. Validates the new name
#   3. Replaces all references across tracked text files (single pass)
#   4. Renames project-specific files (nginx vhost)
#   5. Creates .env from .env.example when missing
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_step()    { echo -e "\n${CYAN}${BOLD}>> $1${NC}"; }

cd "$(dirname "$0")/.."

[ $# -ge 1 ] || log_error "Usage: bash scripts/rename_project.sh <new_name> [--yes] [--dry-run]"

NEW_NAME="$1"
AUTO_CONFIRM=false
DRY_RUN=false

for arg in "$@"; do
  case "${arg}" in
    --yes|-y) AUTO_CONFIRM=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

# -----------------------------------------------------------------------------
# Detect current name from config/application.rb (module MyApp -> my_app)
# -----------------------------------------------------------------------------
[ -f "config/application.rb" ] || log_error "config/application.rb not found. Run from the project root."

OLD_CAMEL=$(sed -n 's/^module \([A-Za-z0-9]*\)$/\1/p' config/application.rb | head -1)
[ -n "${OLD_CAMEL}" ] || log_error "Could not detect the application module in config/application.rb"

# CamelCase -> snake_case (MyAwesomeApp -> my_awesome_app)
OLD_NAME=$(echo "${OLD_CAMEL}" | sed 's/\([A-Z]\)/_\L\1/g;s/^_//')

# Validate new name: lowercase letters, numbers, underscores, starts with letter
if [[ ! "${NEW_NAME}" =~ ^[a-z][a-z0-9_]*$ ]]; then
  log_error "Invalid name: '${NEW_NAME}'\nUse lowercase letters, numbers, and underscores only. Must start with a letter."
fi

if [ "${NEW_NAME}" = "${OLD_NAME}" ]; then
  log_warning "New name is the same as the current name ('${OLD_NAME}'). Nothing to do."
  exit 0
fi

# snake_case -> CamelCase (my_awesome_app -> MyAwesomeApp)
NEW_CAMEL=$(echo "${NEW_NAME}" | sed 's/_\([a-z0-9]\)/\U\1/g;s/^\([a-z]\)/\U\1/')

# snake_case -> Human (my_app -> My App)
OLD_HUMAN=$(echo "${OLD_NAME}" | sed 's/_/ /g;s/\b\(.\)/\u\1/g')
NEW_HUMAN=$(echo "${NEW_NAME}" | sed 's/_/ /g;s/\b\(.\)/\u\1/g')

echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  Rename: ${RED}${OLD_NAME}${NC} -> ${GREEN}${NEW_NAME}${BOLD}${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""
echo -e "  snake_case : ${RED}${OLD_NAME}${NC} -> ${GREEN}${NEW_NAME}${NC}"
echo -e "  CamelCase  : ${RED}${OLD_CAMEL}${NC} -> ${GREEN}${NEW_CAMEL}${NC}"
echo -e "  Human      : ${RED}${OLD_HUMAN}${NC} -> ${GREEN}${NEW_HUMAN}${NC}"
echo ""

if [ "${AUTO_CONFIRM}" = false ] && [ "${DRY_RUN}" = false ]; then
  read -r -p "$(echo -e "${YELLOW}Continue? (y/N):${NC} ")" CONFIRM
  if [[ ! "${CONFIRM}" =~ ^[yY]$ ]]; then
    log_warning "Operation cancelled."
    exit 0
  fi
fi

# -----------------------------------------------------------------------------
# STEP 1 - Replace references in all tracked text files (single pass)
# -----------------------------------------------------------------------------
log_step "STEP 1 - Replacing references in project files..."

# Candidate files: git-tracked plus .env (untracked). Excludes this script
# (its examples/defaults must stay intact) and binary/lock/vendor content.
list_files() {
  {
    if command -v git > /dev/null 2>&1 && git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      git ls-files
    else
      find . -type f \
        -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./vendor/*" \
        -not -path "./tmp/*" -not -path "./log/*" -not -path "./storage/*" \
        | sed 's|^\./||'
    fi
    [ -f ".env" ] && echo ".env"
  } | grep -v -e "^scripts/rename_project.sh$" | sort -u
}

CHANGED=0
while IFS= read -r file; do
  [ -f "${file}" ] || continue
  # Skip binary files
  grep -Iq . "${file}" 2>/dev/null || continue
  # Skip files without any reference to the old name
  if ! grep -q -e "${OLD_NAME}" -e "${OLD_CAMEL}" -e "${OLD_HUMAN}" "${file}"; then
    continue
  fi

  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would update: ${file}"
  else
    perl -0pi -e "s/\Q${OLD_NAME}\E/${NEW_NAME}/g; s/\Q${OLD_CAMEL}\E/${NEW_CAMEL}/g; s/\Q${OLD_HUMAN}\E/${NEW_HUMAN}/g;" "${file}"
    log_success "Updated: ${file}"
  fi
  CHANGED=$((CHANGED + 1))
done < <(list_files)

[ "${CHANGED}" -gt 0 ] || log_warning "No files contained '${OLD_NAME}'. Was the project already renamed?"

# -----------------------------------------------------------------------------
# STEP 2 - Rename project-specific files
# -----------------------------------------------------------------------------
log_step "STEP 2 - Renaming project-specific files..."

if [ -f "docker/nginx/conf.d/${OLD_NAME}.conf" ]; then
  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would rename docker/nginx/conf.d/${OLD_NAME}.conf -> ${NEW_NAME}.conf"
  else
    if command -v git > /dev/null 2>&1 && git ls-files --error-unmatch "docker/nginx/conf.d/${OLD_NAME}.conf" > /dev/null 2>&1; then
      git mv "docker/nginx/conf.d/${OLD_NAME}.conf" "docker/nginx/conf.d/${NEW_NAME}.conf"
    else
      mv "docker/nginx/conf.d/${OLD_NAME}.conf" "docker/nginx/conf.d/${NEW_NAME}.conf"
    fi
    log_success "Renamed: docker/nginx/conf.d/${OLD_NAME}.conf -> ${NEW_NAME}.conf"
  fi
else
  log_info "No nginx vhost to rename."
fi

# -----------------------------------------------------------------------------
# STEP 3 - Ensure .env exists
# -----------------------------------------------------------------------------
log_step "STEP 3 - Validating .env..."

if [ ! -f ".env" ]; then
  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would create .env from .env.example"
  else
    cp .env.example .env
    log_success "Created .env from .env.example"
    log_warning "Update .env with real credentials."
  fi
else
  log_info ".env already exists (references updated in STEP 1)."
fi

echo ""
echo -e "${BOLD}============================================================${NC}"
if [ "${DRY_RUN}" = true ]; then
  echo -e "${GREEN}${BOLD}  Dry-run completed successfully!${NC}"
else
  echo -e "${GREEN}${BOLD}  Project renamed successfully!${NC}"
fi
echo -e "${BOLD}============================================================${NC}"
echo ""
echo -e "  Previous name : ${RED}${OLD_NAME}${NC}"
echo -e "  New name      : ${GREEN}${NEW_NAME}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Check ${CYAN}.env${NC} and set real credentials"
echo -e "  2. Run: ${CYAN}docker compose down -v${NC} (clear volumes from the old name)"
echo -e "  3. Run: ${CYAN}docker compose up --build${NC}"
echo ""
