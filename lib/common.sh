#!/usr/bin/env bash
# Common utilities for GitHub security audit handlers

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

# Check prerequisites
check_gh_installed() {
  if ! command -v gh >/dev/null 2>&1; then
    log_error "GitHub CLI (gh) is not installed."
    return 1
  fi
  return 0
}

check_gh_authenticated() {
  if ! gh auth status >/dev/null 2>&1; then
    log_error "gh is not authenticated. Run: gh auth login"
    return 1
  fi
  return 0
}

check_prerequisites() {
  check_gh_installed || return 1
  check_gh_authenticated || return 1
  
  # Check other required commands
  for cmd in jq date; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_error "Required command '$cmd' is not installed."
      return 1
    fi
  done
  
  return 0
}

# Get list of all repos for owner
get_repos() {
  local owner="$1"
  gh repo list "$owner" --limit 500 --json nameWithOwner,visibility,isArchived --jq '.[] | @base64'
}

# Parse Base64 encoded repo data
decode_repo_json() {
  local row="$1"
  echo "$row" | base64 --decode
}

# Create output directory
ensure_report_dir() {
  local report_dir="$1"
  mkdir -p "$report_dir"
}

# Generate timestamp
get_timestamp() {
  date +%Y%m%d_%H%M%S
}

# Generate human-readable date
get_readable_date() {
  date
}

# Export functions for use in handlers
export -f log_info log_success log_error log_warn
export -f check_gh_installed check_gh_authenticated check_prerequisites
export -f get_repos decode_repo_json ensure_report_dir get_timestamp get_readable_date
