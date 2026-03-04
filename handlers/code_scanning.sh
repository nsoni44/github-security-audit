#!/usr/bin/env bash
# Handler: Code Scanning (GitHub Advanced Security)
# Audits code scanning and SAST configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}" # csv or json

if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing Code Scanning for $OWNER"

if [[ "$OUTPUT_TYPE" == "csv" ]]; then
  echo "repo,visibility,archived,code_scanning_enabled,codeql_configured,has_alerts"
fi

TOTAL=0
CODE_SCANNING_ENABLED=0
CODEQL_CONFIGURED=0
HAS_ALERTS=0

REPOS=$(get_repos "$OWNER")

for row in $REPOS; do
  REPO_JSON=$(decode_repo_json "$row")
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VIS=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCH=$(echo "$REPO_JSON" | jq -r '.isArchived')

  # Fetch security and analysis data
  ANALYSIS_JSON=$(gh api "repos/$REPO" --jq '.security_and_analysis // {}' 2>/dev/null || echo '{}')

  # Check code scanning status from repository security settings
  CODE_SCAN=$(echo "$ANALYSIS_JSON" | jq -r '.advanced_security.status // "unknown"')
  
  # Check if CodeQL workflow exists
  CODEQL="false"
  if gh api "repos/$REPO/actions/workflows" --jq '.workflows[].name' 2>/dev/null | grep -i "codeql\|code.ql" > /dev/null 2>&1; then
    CODEQL="true"
  fi

  # Normalize effective code scanning status
  # For many repos, advanced_security may be "unknown" even when CodeQL workflow is configured.
  EFFECTIVE_CODE_SCAN="$CODE_SCAN"
  if [[ "$CODEQL" == "true" || "$CODE_SCAN" == "enabled" ]]; then
    EFFECTIVE_CODE_SCAN="enabled"
  elif [[ "$CODE_SCAN" == "disabled" ]]; then
    EFFECTIVE_CODE_SCAN="disabled"
  else
    EFFECTIVE_CODE_SCAN="unknown"
  fi

  # Check for alerts (requires admin access, may fail)
  ALERTS="unknown"
  ALERT_COUNT=$(gh api "repos/$REPO/code-scanning/alerts" --jq 'length' 2>/dev/null || echo "0")
  if [[ "$ALERT_COUNT" != "0" ]]; then
    ALERTS="true"
    HAS_ALERTS=$((HAS_ALERTS + 1))
  else
    ALERTS="false"
  fi

  if [[ "$OUTPUT_TYPE" == "csv" ]]; then
    echo "$REPO,$VIS,$ARCH,$EFFECTIVE_CODE_SCAN,$CODEQL,$ALERTS"
  fi

  TOTAL=$((TOTAL + 1))
  [[ "$EFFECTIVE_CODE_SCAN" == "enabled" ]] && CODE_SCANNING_ENABLED=$((CODE_SCANNING_ENABLED + 1))
  [[ "$CODEQL" == "true" ]] && CODEQL_CONFIGURED=$((CODEQL_CONFIGURED + 1))
done

# Output stats to stderr for master script
cat >&2 <<EOF
{
  "handler": "code_scanning",
  "total": $TOTAL,
  "code_scanning_enabled": $CODE_SCANNING_ENABLED,
  "codeql_configured": $CODEQL_CONFIGURED,
  "repos_with_alerts": $HAS_ALERTS
}
EOF
