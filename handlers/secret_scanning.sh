#!/usr/bin/env bash
# Handler: Secret Scanning and Push Protection
# Outputs CSV format for secret scanning and push protection features

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}" # csv or json

# Validate prerequisites
if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing Secret Scanning & Push Protection for $OWNER"

# CSV Header
if [[ "$OUTPUT_TYPE" == "csv" ]]; then
  echo "repo,visibility,archived,secret_scanning,push_protection"
fi

TOTAL=0
SS_ENABLED=0
PP_ENABLED=0
STATS_FILE=$(mktemp)

REPOS=$(get_repos "$OWNER")

for row in $REPOS; do
  REPO_JSON=$(decode_repo_json "$row")
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VIS=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCH=$(echo "$REPO_JSON" | jq -r '.isArchived')

  # Fetch security analysis data
  ANALYSIS_JSON=$(gh api "repos/$REPO" --jq '.security_and_analysis // {}' 2>/dev/null || echo '{}')

  SS=$(echo "$ANALYSIS_JSON" | jq -r '.secret_scanning.status // "na"')
  PP=$(echo "$ANALYSIS_JSON" | jq -r '.secret_scanning_push_protection.status // "na"')

  # Output row
  if [[ "$OUTPUT_TYPE" == "csv" ]]; then
    echo "$REPO,$VIS,$ARCH,$SS,$PP"
  fi

  # Update stats
  TOTAL=$((TOTAL + 1))
  [[ "$SS" == "enabled" ]] && SS_ENABLED=$((SS_ENABLED + 1))
  [[ "$PP" == "enabled" ]] && PP_ENABLED=$((PP_ENABLED + 1))
done

# Store stats for master script
cat > "$STATS_FILE" <<EOF
{
  "handler": "secret_scanning",
  "total": $TOTAL,
  "secret_scanning_enabled": $SS_ENABLED,
  "push_protection_enabled": $PP_ENABLED
}
EOF

# Output stats to stderr so master script can capture
cat "$STATS_FILE" >&2
rm -f "$STATS_FILE"
