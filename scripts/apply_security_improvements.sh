#!/bin/bash

#############################################################################
# GitHub Repository Security Improvements
# Master script to apply all security improvements to your repositories
#############################################################################

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Configuration
OWNER="${1:-}"
DRY_RUN="${2:-true}"

# Validate inputs
if [[ -z "$OWNER" ]]; then
    log_error "Usage: $0 <owner> [dry-run|true|false]"
    log_info "Example: $0 nsoni44 true"
    log_info ""
    log_info "This script will apply the following improvements:"
    log_info "  1. Enable branch protection on default branches"
    log_info "  2. Enable CodeQL code scanning"
    log_info "  3. Enable Dependabot version updates"
    exit 1
fi

# Check prerequisites
check_prerequisites

log_warn "=================================================="
log_warn "GitHub Repository Security Improvements"
log_warn "=================================================="
log_info "Owner: $OWNER"
log_info "Dry Run: $DRY_RUN"
log_warn "=================================================="
log_info ""
log_info "This script will:"
log_info "  ✓ Enable branch protection (1+ review, dismiss stale, no force push)"
log_info "  ✓ Enable CodeQL code scanning via GitHub Actions"
log_info "  ✓ Enable Dependabot version updates (daily)"
log_info ""
log_warn "Requirements:"
log_info "  - You must have admin/write access to the repositories"
log_info "  - GitHub CLI (gh) must be authenticated"
log_info "  - Sufficient API rate limit"
log_info ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes will be made"
    read -p "Preview changes? (yes/no): " confirm
else
    log_error "LIVE MODE - Changes will be applied to your repositories!"
    read -p "I understand and want to proceed (type 'yes' to continue): " confirm
fi

if [[ "$confirm" != "yes" ]]; then
    log_info "Cancelled."
    exit 0
fi

log_warn "=================================================="

#############################################################################
# Execute all improvement scripts
#############################################################################

START_TIME=$(date +%s)

# 1. Code Scanning
log_info ""
log_info "Step 1/3: Enabling CodeQL Code Scanning..."
log_info "=================================================="
if ! AUTO_CONFIRM=yes bash "${SCRIPT_DIR}/enable_code_scanning.sh" "$DRY_RUN" "$OWNER"; then
    log_error "Code scanning setup encountered errors"
fi

# 2. Dependabot Updates
log_info ""
log_info "Step 2/3: Enabling Dependabot Version Updates..."
log_info "=================================================="
if ! AUTO_CONFIRM=yes bash "${SCRIPT_DIR}/enable_dependabot_updates.sh" "$DRY_RUN" "$OWNER" "daily"; then
    log_error "Dependabot setup encountered errors"
fi

# 3. Branch Protection
log_info ""
log_info "Step 3/3: Enabling Branch Protection..."
log_info "=================================================="
if ! AUTO_CONFIRM=yes bash "${SCRIPT_DIR}/enable_branch_protection.sh" "$DRY_RUN" "$OWNER" 1 true true; then
    log_error "Branch protection setup encountered errors"
fi

#############################################################################
# Summary
#############################################################################

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

log_info ""
log_warn "=================================================="
log_success "Security Improvements Complete!"
log_warn "=================================================="
log_info "Completed in: ${DURATION} seconds"
log_info ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes were made"
    log_info ""
    log_info "To apply these changes, run:"
    log_info "  $0 $OWNER false"
    log_info ""
else
    log_success "All security improvements have been applied!"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Verify changes on GitHub"
    log_info "  2. Review branch protection rules"
    log_info "  3. Monitor CodeQL workflow runs"
    log_info "  4. Set up Dependabot alerts notifications"
    log_info ""
fi

log_info "For more information, see: wiki/Improvements-Guide.md"

exit 0
