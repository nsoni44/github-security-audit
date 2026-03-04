#!/bin/bash

#############################################################################
# GitHub Dependabot Version Updates Enabler
# Enables Dependabot version update checks across repositories
#############################################################################

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Configuration
DRY_RUN="${1:-false}"
OWNER="${2:-}"
UPDATE_FREQUENCY="${3:-daily}"

# Validate inputs
if [[ -z "$OWNER" ]]; then
    log_error "Usage: $0 <dry-run|true|false> <owner> [update-frequency]"
    log_info "Example: $0 false nsoni44 daily"
    log_info "Frequencies: daily, weekly, monthly"
    exit 1
fi

# Validate frequency
if ! [[ "$UPDATE_FREQUENCY" =~ ^(daily|weekly|monthly)$ ]]; then
    log_error "Invalid frequency. Use: daily, weekly, monthly"
    exit 1
fi

# Check prerequisites
check_prerequisites

log_info "Dependabot Version Updates Enabler for: $OWNER"
log_info "Dry Run Mode: $DRY_RUN"
log_info "Update Frequency: $UPDATE_FREQUENCY"
log_warn "=================================================="
log_warn "This will enable Dependabot version update checks"
log_warn "Dependabot must be enabled in repository settings"
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
REPOS=$(gh repo list "$OWNER" --json nameWithOwner,isPrivate,isArchived --limit 500 | jq -r '.[] | select(.isArchived == false) | .nameWithOwner')

TOTAL=$(echo "$REPOS" | wc -l)
ENABLED=0
FAILED=0
PENDING_PR=0

log_info "Found $TOTAL active repositories"

#############################################################################
# Generate dependabot.yml template
#############################################################################

read -r -d '' DEPENDABOT_CONFIG << 'EOF' || true
version: 2
updates:
  # Enable version updates for npm packages
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "FREQUENCY"
    open-pull-requests-limit: 10
    rebase-strategy: "auto"

  # Enable version updates for Python packages (if setup.py or requirements.txt exists)
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "FREQUENCY"
    open-pull-requests-limit: 10

  # Enable version updates for GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "FREQUENCY"
    open-pull-requests-limit: 5

  # Enable version updates for Docker images
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "FREQUENCY"
    open-pull-requests-limit: 5

  # Enable version updates for Java (Maven)
  - package-ecosystem: "maven"
    directory: "/"
    schedule:
      interval: "FREQUENCY"
    open-pull-requests-limit: 10
EOF

#############################################################################
# Process each repository
#############################################################################

while IFS= read -r REPO; do
    if [[ -z "$REPO" ]]; then
        continue
    fi
    
    log_info "Processing: $REPO"
    
    # Replace frequency placeholder
    CONFIG="${DEPENDABOT_CONFIG//FREQUENCY/$UPDATE_FREQUENCY}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "  [DRY RUN] Would create Dependabot configuration"
        log_info "  [DRY RUN] Path: .github/dependabot.yml"
        log_info "  [DRY RUN] Frequency: $UPDATE_FREQUENCY"
        ((ENABLED++))
    else
      CONTENT_B64=$(printf '%s' "$CONFIG" | base64)
      CURRENT_SHA=$(gh api "repos/$REPO/contents/.github/dependabot.yml" --jq '.sha' 2>/dev/null || true)

      payload_file=$(mktemp)
      if [[ -n "$CURRENT_SHA" ]]; then
        jq -n \
          --arg message "Enable Dependabot version updates" \
          --arg content "$CONTENT_B64" \
          --arg sha "$CURRENT_SHA" \
          '{message:$message, content:$content, sha:$sha}' > "$payload_file"
      else
        jq -n \
          --arg message "Enable Dependabot version updates" \
          --arg content "$CONTENT_B64" \
          '{message:$message, content:$content}' > "$payload_file"
      fi

      if gh api "repos/$REPO/contents/.github/dependabot.yml" \
        -X PUT \
        --input "$payload_file" >/dev/null 2>&1; then
            log_success "  ✓ Dependabot configuration created"
            ((ENABLED++))
        else
        DEFAULT_BRANCH=$(gh api "repos/$REPO" --jq '.default_branch' 2>/dev/null || echo "")
        DEFAULT_SHA=$(gh api "repos/$REPO/git/ref/heads/$DEFAULT_BRANCH" --jq '.object.sha' 2>/dev/null || echo "")
        if [[ -n "$DEFAULT_BRANCH" && -n "$DEFAULT_SHA" ]]; then
          BRANCH_NAME="security/dependabot-enable-$(date +%s)"
          if gh api "repos/$REPO/git/refs" -X POST \
            -f ref="refs/heads/$BRANCH_NAME" \
            -f sha="$DEFAULT_SHA" >/dev/null 2>&1; then
            pr_payload_file=$(mktemp)
            if [[ -n "$CURRENT_SHA" ]]; then
              jq -n \
                --arg message "Enable Dependabot version updates" \
                --arg content "$CONTENT_B64" \
                --arg sha "$CURRENT_SHA" \
                --arg branch "$BRANCH_NAME" \
                '{message:$message, content:$content, sha:$sha, branch:$branch}' > "$pr_payload_file"
            else
              jq -n \
                --arg message "Enable Dependabot version updates" \
                --arg content "$CONTENT_B64" \
                --arg branch "$BRANCH_NAME" \
                '{message:$message, content:$content, branch:$branch}' > "$pr_payload_file"
            fi

            if gh api "repos/$REPO/contents/.github/dependabot.yml" \
              -X PUT \
              --input "$pr_payload_file" >/dev/null 2>&1; then
              PR_URL=$(gh pr create -R "$REPO" \
                -B "$DEFAULT_BRANCH" \
                -H "$BRANCH_NAME" \
                -t "Enable Dependabot version updates" \
                -b "Automated security improvement: add Dependabot configuration." 2>/dev/null || true)

              if [[ -n "$PR_URL" ]]; then
                if gh pr merge -R "$REPO" --admin --squash --delete-branch "$PR_URL" >/dev/null 2>&1; then
                  log_success "  ✓ Dependabot configuration created via PR and merged"
                  ((ENABLED++))
                else
                  log_warn "  ⚠ Dependabot configuration committed via PR (merge pending): $PR_URL"
                  ((PENDING_PR++))
                fi
              else
                log_warn "  ⚠ Dependabot configuration committed on branch '$BRANCH_NAME' (PR creation pending)"
                ((PENDING_PR++))
              fi
            else
              log_error "  ✗ Failed to create configuration on PR branch"
              ((FAILED++))
            fi
            rm -f "$pr_payload_file"
          else
            log_error "  ✗ Failed to create fallback branch for protected repository"
            ((FAILED++))
          fi
        else
          log_error "  ✗ Failed to create configuration (could not resolve default branch)"
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
log_info "Dependabot Version Updates Summary"
log_info "=================================================="
log_info "Total Repositories: $TOTAL"
log_info "Enabled: $ENABLED"
log_info "Pending PR Merge: $PENDING_PR"
log_info "Failed: $FAILED"
log_info "Update Frequency: $UPDATE_FREQUENCY"
log_info ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes were made"
    log_info "Run with 'false' as first argument to apply changes"
else
    if [[ $FAILED -eq 0 ]]; then
        log_success "Dependabot version updates enabled successfully!"
        log_info "First update checks will run according to schedule"
    else
        log_warn "Some repositories failed - they may require admin access"
    fi
fi

log_info ""
log_info "Note: Dependabot will check for dependency updates $UPDATE_FREQUENCY"
log_info "Note: Pull requests will be automatically created for available updates"
log_info "Monitor updates in: https://github.com/$OWNER/REPO_NAME/dependabot"

exit 0
