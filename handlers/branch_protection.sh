#!/usr/bin/env bash
# Handler: Branch Protection Rules
# Audits branch protection configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}" # csv or json

if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing Branch Protection for $OWNER"

if [[ "$OUTPUT_TYPE" == "csv" ]]; then
  echo "repo,visibility,archived,default_branch,branch_protection_enabled,requires_reviews,requires_status_checks"
fi

TOTAL=0
BP_ENABLED_COUNT=0
REQUIRES_REVIEWS=0
REQUIRES_STATUS=0

REPOS=$(get_repos "$OWNER")

for row in $REPOS; do
  REPO_JSON=$(decode_repo_json "$row")
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VIS=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCH=$(echo "$REPO_JSON" | jq -r '.isArchived')

  # Get default branch
  DEFAULT_BRANCH=$(gh api "repos/$REPO" --jq '.default_branch' 2>/dev/null || echo "unknown")

  # Try to fetch branch protection rules
  BP_DATA=$(gh api "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --jq . 2>/dev/null || echo '{}')

  BP_ENABLED="false"
  REVIEWS="false"
  STATUS="false"

  if [[ $(echo "$BP_DATA" | jq 'has("url")') == "true" ]]; then
    BP_ENABLED="true"
    REVIEWS=$(echo "$BP_DATA" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0' | grep -v "0" > /dev/null 2>&1 && echo "true" || echo "false")
    STATUS=$(echo "$BP_DATA" | jq -r '.required_status_checks' | grep "contexts" > /dev/null 2>&1 && echo "true" || echo "false")
  fi

  if [[ "$OUTPUT_TYPE" == "csv" ]]; then
    echo "$REPO,$VIS,$ARCH,$DEFAULT_BRANCH,$BP_ENABLED,$REVIEWS,$STATUS"
  fi

  TOTAL=$((TOTAL + 1))
  [[ "$BP_ENABLED" == "true" ]] && BP_ENABLED_COUNT=$((BP_ENABLED_COUNT + 1))
  [[ "$REVIEWS" == "true" ]] && REQUIRES_REVIEWS=$((REQUIRES_REVIEWS + 1))
  [[ "$STATUS" == "true" ]] && REQUIRES_STATUS=$((REQUIRES_STATUS + 1))
done

# Output stats to stderr for master script
cat >&2 <<EOF
{
  "handler": "branch_protection",
  "total": $TOTAL,
  "protection_enabled": $BP_ENABLED_COUNT,
  "requires_reviews": $REQUIRES_REVIEWS,
  "requires_status_checks": $REQUIRES_STATUS
}
EOF
