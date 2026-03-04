#!/usr/bin/env bash
# Master SVETRI Security Audit Orchestrator
# Coordinates all security handlers and generates consolidated reports

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
OWNER="${1:-nsoni44}"
REPORT_DIR="${2:-reports}"
EMAIL_TO="${3:-}"
HANDLERS_DIR="${SCRIPT_DIR}/handlers"
TEMP_DIR=$(mktemp -d)
TS="$(get_timestamp)"

# File definitions
CSV_COMBINED="$REPORT_DIR/github_security_audit_combined_${OWNER}_${TS}.csv"
MD_REPORT="$REPORT_DIR/github_security_audit_report_${OWNER}_${TS}.md"
JSON_STATS="$REPORT_DIR/github_security_audit_stats_${OWNER}_${TS}.json"

# Cleanup on exit
trap "rm -rf $TEMP_DIR" EXIT

# Initialize
ensure_report_dir "$REPORT_DIR"

show_svetri_banner
echo ""

log_info "Starting SVETRI security audit for owner: $OWNER"
log_info "Timestamp: $TS"
log_info "Report directory: $REPORT_DIR"

# Verify prerequisites
if ! check_prerequisites; then
  log_error "Prerequisites check failed"
  exit 1
fi

# Create temp file to store handler statistics
STATS_COMBINED="$TEMP_DIR/all_stats.json"
echo "{" > "$STATS_COMBINED"

# Tracking variables
TOTAL_REPOS=0
HANDLER_COUNT=0

# ============================================================================
# Execute Individual Handlers
# ============================================================================

log_info "Running security handlers..."
echo ""

HANDLERS=(
  "secret_scanning"
  "dependabot"
  "branch_protection"
  "code_scanning"
  "repo_config"
)

# Run each handler and capture outputs
for handler in "${HANDLERS[@]}"; do
  HANDLER_SCRIPT="$HANDLERS_DIR/${handler}.sh"
  
  if [[ ! -f "$HANDLER_SCRIPT" ]]; then
    log_warn "Handler not found: $HANDLER_SCRIPT"
    continue
  fi

  log_info "Running handler: $handler"
  
  # Create temp files for output
  CSV_OUTPUT="$TEMP_DIR/${handler}_output.csv"
  STATS_OUTPUT="$TEMP_DIR/${handler}_stats.json"
  
  # Run handler - capture stdout to CSV, stderr to stats
  if bash "$HANDLER_SCRIPT" "$OWNER" "csv" > "$CSV_OUTPUT" 2> "$STATS_OUTPUT"; then
    log_success "Handler completed: $handler"
    
    # Save first CSV for combined report (skip headers from subsequent runs)
    if [[ ! -f "$TEMP_DIR/combined.csv" ]]; then
      cp "$CSV_OUTPUT" "$TEMP_DIR/combined.csv"
    fi
    
    # Store stats in temp file
    if [[ -s "$STATS_OUTPUT" ]]; then
      echo "    \"$handler\": $(cat "$STATS_OUTPUT")," >> "$STATS_COMBINED"
      HANDLER_COUNT=$((HANDLER_COUNT + 1))
    fi
  else
    log_error "Handler failed: $handler"
  fi
  
  echo ""
done

# ============================================================================
# Generate Combined Report
# ============================================================================

log_info "Generating combined report..."

# Get total repos from first CSV (they all have same repos)
TOTAL_REPOS=$(tail -n +2 "$TEMP_DIR/secret_scanning_output.csv" 2>/dev/null | wc -l || echo "0")

# Start markdown report
{
  echo "# SVETRI Security Audit Report"
  echo ""
  echo "**Owner:** $OWNER"  
  echo "**Generated:** $(get_readable_date)"
  echo "**Total Repositories:** $TOTAL_REPOS"
  echo ""
  echo "---"
  echo ""
  
  # Summary section
  echo "## Summary Statistics"
  echo ""
  
  # Parse and display handler stats from files
  for handler in "${HANDLERS[@]}"; do
    STATS_FILE="$TEMP_DIR/${handler}_stats.json"
    if [[ -f "$STATS_FILE" && -s "$STATS_FILE" ]]; then
      HANDLER_TITLE=$(echo "$handler" | sed 's/_/ /g' | sed 's/\b\(.\)/\U\1/g')
      echo "### $HANDLER_TITLE"
      echo "\`\`\`json"
      cat "$STATS_FILE" | jq .
      echo "\`\`\`"
      echo ""
    fi
  done
  
  echo "---"
  echo ""
  echo "## Detailed Results by Handler"
  echo ""
  
} > "$MD_REPORT"

# Add detailed CSV tables for each handler
for handler in "${HANDLERS[@]}"; do
  CSV_FILE="$TEMP_DIR/${handler}_output.csv"
  
  if [[ -f "$CSV_FILE" ]]; then
    HANDLER_TITLE=$(echo "$handler" | sed 's/_/ /g' | sed 's/\b\(.\)/\U\1/g')
    
    {
      echo "### $HANDLER_TITLE"
      echo ""
      
      # Convert CSV to markdown table
      {
        head -n 1 "$CSV_FILE" | tr ',' '|' | sed 's/^/| /' | sed 's/$/ |/'
        echo "|---|---|---|---|---|---|---|---|---|"
        tail -n +2 "$CSV_FILE" | tr ',' '|' | sed 's/^/| /' | sed 's/$/ |/'
      } | head -c 4000  # Limit to first 4000 chars per section
      
      echo ""
      echo ""
    } >> "$MD_REPORT"
  fi
done

# Close off the combined stats JSON
echo "    \"_metadata\": {\"handler_count\": $HANDLER_COUNT}" >> "$STATS_COMBINED"
echo "  }" >> "$STATS_COMBINED"
echo "}" >> "$STATS_COMBINED"

# Generate final JSON Statistics File
log_info "Generating statistics JSON..."

{
  echo "{"
  echo "  \"metadata\": {"
  echo "    \"owner\": \"$OWNER\","
  echo "    \"timestamp\": \"$TS\","
  echo "    \"generated\": \"$(get_readable_date)\","
  echo "    \"total_repositories\": $TOTAL_REPOS"
  echo "  },"
  echo "  \"handlers\": {"
  
  # Insert all handler stats
  first=1
  for handler in "${HANDLERS[@]}"; do
    STATS_FILE="$TEMP_DIR/${handler}_stats.json"
    if [[ -f "$STATS_FILE" && -s "$STATS_FILE" ]]; then
      if [[ $first -eq 0 ]]; then
        echo ","
      fi
      echo -n "    \"$handler\": $(cat "$STATS_FILE" | jq -c .)"
      first=0
    fi
  done
  
  echo ""
  echo "  }"
  echo "}"
} > "$JSON_STATS"

# ============================================================================
# Summary Output
# ============================================================================

log_success "Audit completed successfully!"
echo ""
log_info "Reports generated:"
ls -lh "$MD_REPORT" 2>/dev/null || true
ls -lh "$JSON_STATS" 2>/dev/null || true
echo ""

# ============================================================================
# Email Notification (Optional)
# ============================================================================

if [[ -n "$EMAIL_TO" ]]; then
  log_info "Sending email to: $EMAIL_TO"
  
  if command -v mail >/dev/null 2>&1; then
    SUBJECT="GitHub Security Audit Report ($OWNER) - $TS"
    
    # Create email body with key statistics
    {
      echo "GitHub Security Audit Report"
      echo "============================="
      echo ""
      echo "Owner: $OWNER"
      echo "Generated: $(get_readable_date)"
      echo "Total Repositories: $TOTAL_REPOS"
      echo ""
      echo "Detailed report attached."
      echo ""
      echo "Key Findings:"
      for handler in "${HANDLERS[@]}"; do
        STATS_FILE="$TEMP_DIR/${handler}_stats.json"
        if [[ -f "$STATS_FILE" && -s "$STATS_FILE" ]]; then
          HANDLER_NAME=$(cat "$STATS_FILE" | jq -r '.handler' 2>/dev/null || echo "$handler")
          echo "- $HANDLER_NAME"
        fi
      done
    } | mail -s "$SUBJECT" "$EMAIL_TO"
    
    log_success "Email sent successfully"
  else
    log_warn "Email not sent (mail command not available)"
    log_info "Reports available at: $REPORT_DIR"
  fi
fi

echo ""
log_info "Master audit script completed"
