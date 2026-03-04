#!/usr/bin/env bash
set -euo pipefail

OWNER="${1:-nsoni44}"
REPORT_DIR="${2:-reports}"
EMAIL_TO="${3:-}"

mkdir -p "$REPORT_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
CSV_FILE="$REPORT_DIR/github_security_audit_${OWNER}_${TS}.csv"
MD_FILE="$REPORT_DIR/github_security_audit_${OWNER}_${TS}.md"

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: GitHub CLI (gh) is not installed."
  exit 1
fi

gh auth status >/dev/null 2>&1 || {
  echo "Error: gh is not authenticated. Run: gh auth login"
  exit 1
}

echo "repo,visibility,archived,secret_scanning,push_protection,dependabot_security_updates" > "$CSV_FILE"

TOTAL=0
SS_ENABLED=0
PP_ENABLED=0
DEP_ENABLED=0

REPOS=$(gh repo list "$OWNER" --limit 500 --json nameWithOwner,visibility,isArchived --jq '.[] | @base64')

for row in $REPOS; do
  _jq() {
    echo "$row" | base64 --decode | jq -r "$1"
  }

  REPO=$(_jq '.nameWithOwner')
  VIS=$(_jq '.visibility')
  ARCH=$(_jq '.isArchived')

  ANALYSIS_JSON=$(gh api "repos/$REPO" --jq '.security_and_analysis // {}')

  SS=$(echo "$ANALYSIS_JSON" | jq -r '.secret_scanning.status // "na"')
  PP=$(echo "$ANALYSIS_JSON" | jq -r '.secret_scanning_push_protection.status // "na"')
  DEP=$(echo "$ANALYSIS_JSON" | jq -r '.dependabot_security_updates.status // "na"')

  echo "$REPO,$VIS,$ARCH,$SS,$PP,$DEP" >> "$CSV_FILE"

  TOTAL=$((TOTAL + 1))
  [[ "$SS" == "enabled" ]] && SS_ENABLED=$((SS_ENABLED + 1))
  [[ "$PP" == "enabled" ]] && PP_ENABLED=$((PP_ENABLED + 1))
  [[ "$DEP" == "enabled" ]] && DEP_ENABLED=$((DEP_ENABLED + 1))
done

{
  echo "# GitHub Security Audit Report"
  echo
  echo "- Owner: $OWNER"
  echo "- Generated: $(date)"
  echo "- Total repos: $TOTAL"
  echo "- Secret scanning enabled: $SS_ENABLED/$TOTAL"
  echo "- Push protection enabled: $PP_ENABLED/$TOTAL"
  echo "- Dependabot security updates enabled: $DEP_ENABLED/$TOTAL"
  echo
  echo "## Detailed Results"
  echo
  echo "| Repo | Visibility | Archived | Secret Scanning | Push Protection | Dependabot Security Updates |"
  echo "|---|---|---:|---|---|---|"

  tail -n +2 "$CSV_FILE" | while IFS=',' read -r repo vis arch ss pp dep; do
    echo "| $repo | $vis | $arch | $ss | $pp | $dep |"
  done
} > "$MD_FILE"

echo "Report generated:"
echo "- $CSV_FILE"
echo "- $MD_FILE"

if [[ -n "$EMAIL_TO" ]]; then
  if command -v mail >/dev/null 2>&1; then
    mail -s "GitHub Security Audit Report ($OWNER) - $TS" "$EMAIL_TO" < "$MD_FILE"
    echo "Email sent to: $EMAIL_TO"
  else
    echo "Email not sent (mail command not available)."
    echo "You can still share the report file manually: $MD_FILE"
  fi
fi
