#!/bin/bash

#############################################################################
# GitHub CodeQL Scanning Enabler
# Enables CodeQL analysis workflows on repositories
#############################################################################

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Configuration
DRY_RUN="${1:-false}"
OWNER="${2:-}"
LANGUAGES="${3:-javascript,typescript,python,java,cpp,csharp,go,ruby}"

# Validate inputs
if [[ -z "$OWNER" ]]; then
    log_error "Usage: $0 <dry-run|true|false> <owner> [languages]"
    log_info "Example: $0 false nsoni44"
    log_info "Languages: javascript,typescript,python,java,cpp,csharp,go,ruby"
    exit 1
fi

# Check prerequisites
check_prerequisites

log_info "CodeQL Scanner Enabler for: $OWNER"
log_info "Dry Run Mode: $DRY_RUN"
log_info "Languages: $LANGUAGES"
log_warn "=================================================="
log_warn "This will enable CodeQL scanning via GitHub Actions"
log_warn "Repositories must have Actions enabled"
log_warn "=================================================="
confirm="${AUTO_CONFIRM:-}"
if [[ -z "$confirm" ]]; then
  read -p "Continue? (yes/no): " confirm
fi
if [[ "$confirm" != "yes" ]]; then
    log_info "Cancelled."
    exit 0
fi

#############################################################################
# Get repositories
#############################################################################

log_info "Fetching repositories for $OWNER..."
REPOS=$(gh repo list "$OWNER" --json nameWithOwner,isPrivate,isArchived,primaryLanguage --limit 500 | jq -r '.[] | select(.isArchived == false) | .nameWithOwner')

TOTAL=$(echo "$REPOS" | wc -l)
ENABLED=0
FAILED=0
PENDING_PR=0

log_info "Found $TOTAL active repositories"

#############################################################################
# CodeQL Workflow Template
#############################################################################

read -r -d '' CODEQL_WORKFLOW << 'EOF' || true
name: "CodeQL"

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master ]
  schedule:
    - cron: '23 2 * * 1'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v2
        with:
          languages: 'javascript,typescript,python,java,cpp,csharp,go,ruby'
          queries: security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@v2

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v2
EOF

#############################################################################
# Process each repository
#############################################################################

while IFS= read -r REPO; do
    if [[ -z "$REPO" ]]; then
        continue
    fi
    
    log_info "Processing: $REPO"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "  [DRY RUN] Would create CodeQL workflow"
        log_info "  [DRY RUN] Path: .github/workflows/codeql.yml"
        ((ENABLED++))
    else
      CONTENT_B64=$(printf '%s' "$CODEQL_WORKFLOW" | base64)
      CURRENT_SHA=$(gh api "repos/$REPO/contents/.github/workflows/codeql.yml" --jq '.sha' 2>/dev/null || true)

      payload_file=$(mktemp)
      if [[ -n "$CURRENT_SHA" ]]; then
        jq -n \
          --arg message "Enable CodeQL code scanning" \
          --arg content "$CONTENT_B64" \
          --arg sha "$CURRENT_SHA" \
          '{message:$message, content:$content, sha:$sha}' > "$payload_file"
      else
        jq -n \
          --arg message "Enable CodeQL code scanning" \
          --arg content "$CONTENT_B64" \
          '{message:$message, content:$content}' > "$payload_file"
      fi

      if gh api "repos/$REPO/contents/.github/workflows/codeql.yml" \
        -X PUT \
        --input "$payload_file" >/dev/null 2>&1; then
            log_success "  ✓ CodeQL workflow created"
            ((ENABLED++))
        else
        DEFAULT_BRANCH=$(gh api "repos/$REPO" --jq '.default_branch' 2>/dev/null || echo "")
        DEFAULT_SHA=$(gh api "repos/$REPO/git/ref/heads/$DEFAULT_BRANCH" --jq '.object.sha' 2>/dev/null || echo "")
        if [[ -n "$DEFAULT_BRANCH" && -n "$DEFAULT_SHA" ]]; then
          BRANCH_NAME="security/codeql-enable-$(date +%s)"
          if gh api "repos/$REPO/git/refs" -X POST \
            -f ref="refs/heads/$BRANCH_NAME" \
            -f sha="$DEFAULT_SHA" >/dev/null 2>&1; then
            pr_payload_file=$(mktemp)
            if [[ -n "$CURRENT_SHA" ]]; then
              jq -n \
                --arg message "Enable CodeQL code scanning" \
                --arg content "$CONTENT_B64" \
                --arg sha "$CURRENT_SHA" \
                --arg branch "$BRANCH_NAME" \
                '{message:$message, content:$content, sha:$sha, branch:$branch}' > "$pr_payload_file"
            else
              jq -n \
                --arg message "Enable CodeQL code scanning" \
                --arg content "$CONTENT_B64" \
                --arg branch "$BRANCH_NAME" \
                '{message:$message, content:$content, branch:$branch}' > "$pr_payload_file"
            fi

            if gh api "repos/$REPO/contents/.github/workflows/codeql.yml" \
              -X PUT \
              --input "$pr_payload_file" >/dev/null 2>&1; then
              PR_URL=$(gh pr create -R "$REPO" \
                -B "$DEFAULT_BRANCH" \
                -H "$BRANCH_NAME" \
                -t "Enable CodeQL code scanning" \
                -b "Automated security improvement: add CodeQL workflow." 2>/dev/null || true)

              if [[ -n "$PR_URL" ]]; then
                if gh pr merge -R "$REPO" --admin --squash --delete-branch "$PR_URL" >/dev/null 2>&1; then
                  log_success "  ✓ CodeQL workflow created via PR and merged"
                  ((ENABLED++))
                else
                  log_warn "  ⚠ CodeQL workflow committed via PR (merge pending): $PR_URL"
                  ((PENDING_PR++))
                fi
              else
                log_warn "  ⚠ CodeQL workflow committed on branch '$BRANCH_NAME' (PR creation pending)"
                ((PENDING_PR++))
              fi
            else
              log_error "  ✗ Failed to create workflow on PR branch"
              ((FAILED++))
            fi
            rm -f "$pr_payload_file"
          else
            log_error "  ✗ Failed to create fallback branch for protected repository"
            ((FAILED++))
          fi
        else
          log_error "  ✗ Failed to create workflow (could not resolve default branch)"
          ((FAILED++))
        fi
        fi
      rm -f "$payload_file"
    fi
    
done <<< "$REPOS"

#############################################################################
# Summary
#############################################################################

log_info ""
log_info "=================================================="
log_info "CodeQL Scanning Summary"
log_info "=================================================="
log_info "Total Repositories: $TOTAL"
log_info "Enabled: $ENABLED"
log_info "Pending PR Merge: $PENDING_PR"
log_info "Failed: $FAILED"
log_info ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes were made"
    log_info "Run with 'false' as first argument to apply changes"
else
    if [[ $FAILED -eq 0 ]]; then
        log_success "CodeQL scanning enabled successfully!"
        log_info "Workflows will be automatically triggered on push to main/master"
    else
        log_warn "Some repositories failed - they may require admin access"
    fi
fi

log_info ""
log_info "Note: CodeQL workflows require GitHub Actions to be enabled"
log_info "Note: First scan may take 5-10 minutes to complete"
log_info "Monitor progress in: https://github.com/$OWNER/REPO_NAME/security/code-scanning"

exit 0
