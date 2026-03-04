#!/usr/bin/env bash
# Handler: Repository Configuration Audit
# Audits repo-level settings and configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}" # csv or json

if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing Repository Configuration for $OWNER"

if [[ "$OUTPUT_TYPE" == "csv" ]]; then
  echo "repo,visibility,archived,has_description,has_homepage,has_wiki,has_pages,allow_fork,allow_downloads"
fi

TOTAL=0
HAS_DESCRIPTION=0
HAS_HOMEPAGE=0
HAS_WIKI=0
HAS_PAGES=0
FORK_ALLOWED=0
DOWNLOADS_ALLOWED=0

REPOS=$(get_repos "$OWNER")

for row in $REPOS; do
  REPO_JSON=$(decode_repo_json "$row")
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VIS=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCH=$(echo "$REPO_JSON" | jq -r '.isArchived')

  # Fetch full repo data
  REPO_DATA=$(gh api "repos/$REPO" 2>/dev/null || echo '{}')

  DESC=$(echo "$REPO_DATA" | jq -r '.description // ""' | grep -q . && echo "true" || echo "false")
  HOMEPAGE=$(echo "$REPO_DATA" | jq -r '.homepage // ""' | grep -q . && echo "true" || echo "false")
  WIKI=$(echo "$REPO_DATA" | jq -r '.has_wiki' 2>/dev/null || echo "false")
  PAGES=$(echo "$REPO_DATA" | jq -r '.has_pages' 2>/dev/null || echo "false")
  FORK=$(echo "$REPO_DATA" | jq -r '.allow_forking' 2>/dev/null || echo "unknown")
  DOWNLOADS=$(echo "$REPO_DATA" | jq -r '.has_downloads' 2>/dev/null || echo "unknown")

  if [[ "$OUTPUT_TYPE" == "csv" ]]; then
    echo "$REPO,$VIS,$ARCH,$DESC,$HOMEPAGE,$WIKI,$PAGES,$FORK,$DOWNLOADS"
  fi

  TOTAL=$((TOTAL + 1))
  [[ "$DESC" == "true" ]] && HAS_DESCRIPTION=$((HAS_DESCRIPTION + 1))
  [[ "$HOMEPAGE" == "true" ]] && HAS_HOMEPAGE=$((HAS_HOMEPAGE + 1))
  [[ "$WIKI" == "true" ]] && HAS_WIKI=$((HAS_WIKI + 1))
  [[ "$PAGES" == "true" ]] && HAS_PAGES=$((HAS_PAGES + 1))
  [[ "$FORK" == "true" ]] && FORK_ALLOWED=$((FORK_ALLOWED + 1))
  [[ "$DOWNLOADS" == "true" ]] && DOWNLOADS_ALLOWED=$((DOWNLOADS_ALLOWED + 1))
done

# Output stats to stderr for master script
cat >&2 <<EOF
{
  "handler": "repo_config",
  "total": $TOTAL,
  "with_description": $HAS_DESCRIPTION,
  "with_homepage": $HAS_HOMEPAGE,
  "wiki_enabled": $HAS_WIKI,
  "pages_enabled": $HAS_PAGES,
  "forking_allowed": $FORK_ALLOWED,
  "downloads_allowed": $DOWNLOADS_ALLOWED
}
EOF
