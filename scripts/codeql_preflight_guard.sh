#!/bin/bash

#############################################################################
# CodeQL Preflight Guard
# Audits repositories for CodeQL workflow risks before bulk rollout.
#############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:-}"
REPORT_DIR="${2:-reports}"
FAIL_ON_CRITICAL="${3:-false}"

if [[ -z "$OWNER" ]]; then
  log_error "Usage: $0 <owner> [report-dir] [fail-on-critical|true|false]"
  log_info "Example: $0 nsoni44 reports true"
  exit 1
fi

check_prerequisites
ensure_report_dir "$REPORT_DIR"

TS="$(get_timestamp)"
CSV_FILE="$REPORT_DIR/codeql_preflight_${OWNER}_${TS}.csv"
MD_FILE="$REPORT_DIR/codeql_preflight_${OWNER}_${TS}.md"

CRITICAL=0
WARNINGS=0
ANALYZED=0

echo "repo,default_branch,workflow_path,status,severity,findings,recommended_action" > "$CSV_FILE"

contains_lang() {
  local lang="$1"
  local csv="$2"
  [[ ",${csv}," == *",${lang},"* ]]
}

normalize_lang_csv() {
  local raw="$1"
  echo "$raw" | tr '[:upper:]' '[:lower:]' | tr -d "'\" " | tr ';' ',' | tr -s ',' | sed 's/^,//; s/,$//'
}

detect_repo_languages() {
  local repo="$1"
  local detected=""
  local tree
  tree=$(gh api "repos/$repo/git/trees/HEAD?recursive=1" --jq '.tree[].path' 2>/dev/null || true)

  if echo "$tree" | grep -Eq '^\.github/workflows/.*\.(yml|yaml)$'; then
    detected="actions"
  fi
  if echo "$tree" | grep -Eq '\.(js|jsx|ts|tsx)$'; then
    detected="${detected},javascript"
  fi
  if echo "$tree" | grep -Eq '\.py$'; then
    detected="${detected},python"
  fi
  if echo "$tree" | grep -Eq '\.rb$'; then
    detected="${detected},ruby"
  fi
  if echo "$tree" | grep -Eq '\.go$'; then
    detected="${detected},go"
  fi
  if echo "$tree" | grep -Eq '\.java$'; then
    detected="${detected},java"
  fi
  if echo "$tree" | grep -Eq '\.(c|cc|cpp|cxx|h|hpp)$'; then
    detected="${detected},cpp"
  fi
  if echo "$tree" | grep -Eq '\.cs$'; then
    detected="${detected},csharp"
  fi

  normalize_lang_csv "$detected"
}

read_codeql_workflow() {
  local repo="$1"
  local workflow_paths
  workflow_paths=$(gh api "repos/$repo/contents/.github/workflows" --jq '.[].path' 2>/dev/null || true)

  if [[ -z "$workflow_paths" ]]; then
    echo "|"
    return
  fi

  while IFS= read -r wf; do
    [[ -z "$wf" ]] && continue
    local content
    content=$(gh api "repos/$repo/contents/$wf" --jq '.content' 2>/dev/null | tr -d '\n' | base64 --decode 2>/dev/null || true)
    if echo "$content" | grep -Eq 'github/codeql-action/(init|analyze)@'; then
      echo "$wf|$content"
      return
    fi
  done <<< "$workflow_paths"

  echo "|"
}

log_info "Running CodeQL preflight guard for owner: $OWNER"

REPOS=$(gh repo list "$OWNER" --json nameWithOwner,isArchived --limit 500 | jq -r '.[] | select(.isArchived == false) | .nameWithOwner')

while IFS= read -r REPO; do
  [[ -z "$REPO" ]] && continue

  default_branch=$(gh api "repos/$REPO" --jq '.default_branch' 2>/dev/null || echo "main")
  repo_langs=$(detect_repo_languages "$REPO")

  wf_data=$(read_codeql_workflow "$REPO")
  wf_path="${wf_data%%|*}"
  wf_content="${wf_data#*|}"

  status="ok"
  severity="info"
  findings="none"
  action="none"

  if [[ -z "$wf_path" ]]; then
    status="missing_workflow"
    severity="warning"
    findings="No CodeQL workflow found"
    action="Create workflow with codeql-action@v3 and language autodetect"
    WARNINGS=$((WARNINGS + 1))
  else
    configured_langs=$(echo "$wf_content" | awk -F': ' '/^[[:space:]]*languages:[[:space:]]*/ {print $2; exit}' | sed 's/#.*$//' | xargs || true)
    configured_langs=$(normalize_lang_csv "$configured_langs")

    if echo "$wf_content" | grep -Eq 'github/codeql-action/(init|autobuild|analyze)@v2'; then
      status="invalid"
      severity="critical"
      findings="Deprecated CodeQL action v2 detected"
      action="Upgrade all CodeQL actions to v3"
    fi

    if echo "$wf_content" | grep -Eq 'github/codeql-action/autobuild@'; then
      if [[ "$status" == "ok" ]]; then
        status="risky"
        severity="warning"
        findings="Autobuild is enabled"
        action="Use explicit/manual build for compiled languages or remove autobuild"
      else
        findings="${findings}; Autobuild is enabled"
      fi
    fi

    compiled_in_config="false"
    for c in java go cpp csharp; do
      if contains_lang "$c" "$configured_langs"; then
        compiled_in_config="true"
      fi
    done

    if [[ "$compiled_in_config" == "true" ]]; then
      if ! echo "$wf_content" | grep -Eq '^[[:space:]]*-[[:space:]]name:[[:space:]].*(Build|Compile)|^[[:space:]]*run:[[:space:]].*(mvn|gradle|go build|dotnet build|cmake|make)'; then
        status="invalid"
        severity="critical"
        findings="${findings}; Compiled language configured without explicit build step"
        action="Add manual build steps or remove compiled languages from CodeQL config"
      fi
    fi

    for l in javascript python ruby go java cpp csharp; do
      if contains_lang "$l" "$configured_langs" && ! contains_lang "$l" "$repo_langs"; then
        if [[ "$status" == "ok" ]]; then
          status="mismatch"
          severity="warning"
          findings="Configured language '$l' but no matching source files found"
          action="Align CodeQL languages with actual repository source files"
        else
          findings="${findings}; Configured '$l' without matching source"
        fi
      fi
    done

    if [[ "$severity" == "critical" ]]; then
      CRITICAL=$((CRITICAL + 1))
    elif [[ "$severity" == "warning" ]]; then
      WARNINGS=$((WARNINGS + 1))
    fi
  fi

  ANALYZED=$((ANALYZED + 1))
  findings=$(echo "$findings" | sed 's/^none; //; s/; / | /g')
  echo "$REPO,$default_branch,${wf_path:-none},$status,$severity,\"$findings\",\"$action\"" >> "$CSV_FILE"
done <<< "$REPOS"

{
  echo "# CodeQL Preflight Guard Report"
  echo ""
  echo "- Owner: $OWNER"
  echo "- Generated: $(get_readable_date)"
  echo "- Repositories analyzed: $ANALYZED"
  echo "- Critical findings: $CRITICAL"
  echo "- Warning findings: $WARNINGS"
  echo ""
  echo "## Findings"
  echo ""
  echo "| Repo | Branch | Workflow | Status | Severity | Findings | Recommended Action |"
  echo "|---|---|---|---|---|---|---|"
  tail -n +2 "$CSV_FILE" | while IFS=',' read -r repo branch wf status severity findings action; do
    echo "| $repo | $branch | $wf | $status | $severity | ${findings//\"/} | ${action//\"/} |"
  done
} > "$MD_FILE"

log_success "CodeQL preflight report generated"
log_info "- $CSV_FILE"
log_info "- $MD_FILE"

if [[ "$FAIL_ON_CRITICAL" == "true" && $CRITICAL -gt 0 ]]; then
  log_error "Preflight failed: $CRITICAL critical finding(s) detected"
  exit 2
fi

exit 0
