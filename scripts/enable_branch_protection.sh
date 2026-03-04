#!/bin/bash

#############################################################################
# GitHub Branch Protection Enabler
# Enables branch protection rules on default branches across repositories
#############################################################################

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Configuration
DRY_RUN="${1:-false}"
OWNER="${2:-}"
REQUIRE_REVIEWS="${3:-1}"
DISMISS_STALE="${4:-true}"
REQUIRE_STATUS_CHECKS="${5:-true}"

# Validate inputs
if [[ -z "$OWNER" ]]; then
    log_error "Usage: $0 <dry-run|true|false> <owner> [require_reviews] [dismiss_stale] [require_status_checks]"
    log_info "Example: $0 false nsoni44 1 true true"
    exit 1
fi

# Check prerequisites
check_prerequisites

log_info "Branch Protection Enabler for: $OWNER"
log_info "Dry Run Mode: $DRY_RUN"
log_info "Require Reviews: $REQUIRE_REVIEWS"
log_info "Dismiss Stale Reviews: $DISMISS_STALE"
log_info "Require Status Checks: $REQUIRE_STATUS_CHECKS"
log_warn "=================================================="
log_warn "This will enable branch protection on all public repositories"
log_warn "Private repositories require additional verification"
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
PROTECTED=0
FAILED=0

log_info "Found $TOTAL active repositories"

#############################################################################
# Process each repository
#############################################################################

while IFS= read -r REPO; do
    if [[ -z "$REPO" ]]; then
        continue
    fi
    
    log_info "Processing: $REPO"
    
    # Get default branch
    DEFAULT_BRANCH=$(gh repo view "$REPO" --json defaultBranchRef --jq '.defaultBranchRef.name')
    
    if [[ -z "$DEFAULT_BRANCH" ]]; then
        log_error "  ✗ Could not determine default branch"
        ((FAILED++))
        continue
    fi
    
    log_info "  Default branch: $DEFAULT_BRANCH"
    
    # Build the protection rule
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "  [DRY RUN] Would enable protection on branch: $DEFAULT_BRANCH"
        log_info "  [DRY RUN] Command:"
        log_info "  [DRY RUN]   gh api repos/$REPO/branches/$DEFAULT_BRANCH/protection"
        ((PROTECTED++))
    else
        # Enable branch protection
        payload_file=$(mktemp)
                jq -n \
                        --argjson reviews "$REQUIRE_REVIEWS" \
                        --argjson dismiss_stale "$( [[ "$DISMISS_STALE" == "true" ]] && echo true || echo false )" \
                        --argjson require_checks "$( [[ "$REQUIRE_STATUS_CHECKS" == "true" ]] && echo true || echo false )" \
                        '{
                            required_status_checks: (if $require_checks then {strict:true, contexts:[]} else null end),
                            enforce_admins: true,
                            required_pull_request_reviews: (
                                if $reviews > 0 then
                                    {
                                        dismiss_stale_reviews: $dismiss_stale,
                                        require_code_owner_reviews: false,
                                        required_approving_review_count: $reviews
                                    }
                                else
                                    null
                                end
                            ),
                            restrictions: null,
                            required_linear_history: false,
                            allow_force_pushes: false,
                            allow_deletions: false,
                            block_creations: false,
                            required_conversation_resolution: ($reviews > 0),
                            lock_branch: false,
                            allow_fork_syncing: true
                        }' > "$payload_file"

        if gh api "repos/$REPO/branches/$DEFAULT_BRANCH/protection" \
            -X PUT \
            --input "$payload_file" 2>/dev/null; then
            log_success "  ✓ Branch protection enabled"
            ((PROTECTED++))
        else
            log_error "  ✗ Failed to enable branch protection (may require admin access)"
            ((FAILED++))
        fi
        rm -f "$payload_file"
    fi
    
done <<< "$REPOS"

#############################################################################
# Summary
#############################################################################

log_info ""
log_info "=================================================="
log_info "Branch Protection Summary"
log_info "=================================================="
log_info "Total Repositories: $TOTAL"
log_info "Protected: $PROTECTED"
log_info "Failed: $FAILED"
log_info ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes were made"
    log_info "Run with 'false' as first argument to apply changes"
else
    if [[ $FAILED -eq 0 ]]; then
        log_success "All repositories protected successfully!"
    else
        log_warn "Some repositories failed - they may require owner/admin access"
    fi
fi

exit 0
