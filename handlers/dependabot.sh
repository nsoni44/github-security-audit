#!/usr/bin/env bash
# Handler: Dependabot Security Updates and Version Updates
# Outputs CSV format for dependabot configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}" # csv or json

if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing Dependabot for $OWNER"

if [[ "$OUTPUT_TYPE" == "csv" ]]; then
  echo "repo,visibility,archived,dependabot_security_updates,dependabot_version_updates"
fi

TOTAL=0
DEP_SEC_ENABLED=0
DEP_VER_ENABLED=0

REPOS=$(get_repos "$OWNER")

for row in $REPOS; do
  REPO_JSON=$(decode_repo_json "$row")
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VIS=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCH=$(echo "$REPO_JSON" | jq -r '.isArchived')

  # Fetch security analysis and dependabot data
  REPO_DATA=$(gh api "repos/$REPO" --jq '.security_and_analysis // {}' 2>/dev/null || echo '{}')

  DEP_SEC=$(echo "$REPO_DATA" | jq -r '.dependabot_security_updates.status // "na"')
  
  # Check for version updates (requires checking dependabot config)
  DEP_VER="unknown"
  if [[ "$DEP_SEC" != "na" ]]; then
    # Try to fetch dependabot config
    if gh api "repos/$REPO/contents/.github/dependabot.yml" >/dev/null 2>&1; then
      DEP_VER="configured"
    else
      DEP_VER="not_configured"
    fi
  fi

  if [[ "$OUTPUT_TYPE" == "csv" ]]; then
    echo "$REPO,$VIS,$ARCH,$DEP_SEC,$DEP_VER"
  fi

  TOTAL=$((TOTAL + 1))
  [[ "$DEP_SEC" == "enabled" ]] && DEP_SEC_ENABLED=$((DEP_SEC_ENABLED + 1))
  [[ "$DEP_VER" == "configured" ]] && DEP_VER_ENABLED=$((DEP_VER_ENABLED + 1))
done

# Output stats to stderr for master script
cat >&2 <<EOF
{
  "handler": "dependabot",
  "total": $TOTAL,
  "security_updates_enabled": $DEP_SEC_ENABLED,
  "version_updates_configured": $DEP_VER_ENABLED
}
EOF
