# Handler Development

Guide for creating custom security audit handlers to extend the system.

---

## Overview

Handlers are independent bash scripts that audit specific security domains. Each handler:
-  Fetches repository data via GitHub API
- Performs domain-specific analysis
- Outputs CSV data to stdout
- Outputs JSON statistics to stderr

---

## Handler Architecture

### Standard Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# Import common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Parse arguments
OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}"

# Verify prerequisites
if ! check_prerequisites; then
  exit 1
fi

# Main logic
log_info "Auditing [FEATURE] for $OWNER"

# Output CSV header
echo "repo,visibility,archived,[YOUR_METRICS]"

# Audit logic...

# Output statistics to stderr
cat >&2 <<EOF
{
  "handler": "handler_name",
  "total": $TOTAL,
  "metric1": $VALUE1,
  "metric2": $VALUE2
}
EOF
```

---

## Creating a Custom Handler

### Step 1: Copy Template

```bash
cd handlers/
cp secret_scanning.sh my_custom_handler.sh
chmod +x my_custom_handler.sh
```

### Step 2: Modify Handler Logic

**Replace audit logic with your checks:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}"

if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing Custom Feature for $OWNER"

# Output CSV header
echo "repo,visibility,archived,custom_metric1,custom_metric2"

# Initialize counters
TOTAL=0
METRIC1_COUNT=0
METRIC2_COUNT=0

# Fetch and process repositories
while IFS= read -r row; do
  # Decode repository data
  REPO_JSON=$(decode_repo_json "$row")
  
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VISIBILITY=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCHIVED=$(echo "$REPO_JSON" | jq -r '.isArchived')
  
  # Skip archived repos
  if [[ "$ARCHIVED" == "true" ]]; then
    continue
  fi
  
  ((TOTAL++))
  
  # Your custom API calls and logic here
  METRIC1=$(gh api "/repos/$REPO/custom-endpoint" | jq -r '.field1')
  METRIC2=$(gh api "/repos/$REPO/custom-endpoint" | jq -r '.field2')
  
  # Track metrics
  if [[ "$METRIC1" == "expected_value" ]]; then
    ((METRIC1_COUNT++))
  fi
  
  # Output CSV row
  echo "$REPO,$VISIBILITY,$ARCHIVED,$METRIC1,$METRIC2"
  
done < <(get_repos "$OWNER")

# Output statistics to stderr for master script
cat >&2 <<EOF
{
  "handler": "custom_handler",
  "total": $TOTAL,
  "metric1_count": $METRIC1_COUNT,
  "metric2_count": $METRIC2_COUNT
}
EOF

log_success "Custom handler completed: $TOTAL repositories audited"
```

### Step 3: Register Handler

Add your handler to `scripts/audit_master.sh`:

```bash
# Array of handlers
HANDLERS=(
  "secret_scanning"
  "dependabot"
  "branch_protection"
  "code_scanning"
  "repo_config"
  "my_custom_handler"    # Add your handler
)
```

### Step 4: Test Handler

```bash
# Test standalone
./handlers/my_custom_handler.sh YOUR_OWNER

# Test within master script
./scripts/audit_master.sh YOUR_OWNER reports
```

---

## Handler Requirements

### Required Outputs

**1. CSV to stdout:**
```csv
repo,visibility,archived,metric1,metric2
owner/repo1,PUBLIC,false,enabled,true
owner/repo2,PRIVATE,false,disabled,false
```

**2. JSON statistics to stderr:**
```json
{
  "handler": "handler_name",
  "total": 10,
  "metric1_enabled": 8,
  "metric2_enabled": 9
}
```

### Best Practices

✅ **DO:**
- Use `set -euo pipefail` for error handling
- Source `lib/common.sh` for utilities
- Validate input parameters
- Log informative messages
- Handle API errors gracefully
- Skip archived repositories
- Output valid CSV/JSON
- Document your metrics

❌ **DON'T:**
- Hardcode credentials
- Make destructive API calls
- Ignore error conditions
- Output to stderr except statistics
- Modify repository settings
- Assume repository structure

---

## Available Library Functions

From `lib/common.sh`:

### Logging

```bash
log_info "Informational message"      # Blue [INFO]
log_success "Success message"         # Green [✓]
log_error "Error message"             # Red [ERROR]
log_warn "Warning message"            # Yellow [WARN]
```

### Prerequisites

```bash
check_gh_installed        # Check if gh CLI installed
check_gh_authenticated    # Check if gh authenticated
check_prerequisites       # Check all prerequisites
```

### Repository Operations

```bash
get_repos "$OWNER"        # Get all repos for owner (Base64 encoded)
decode_repo_json "$row"   # Decode Base64 repo data to JSON
```

### Utilities

```bash
ensure_report_dir "$dir"  # Create directory if not exists
get_timestamp             # Get timestamp (YYYYMMDD_HHMMSS)
get_readable_date         # Get human-readable date
```

---

## Example Handlers

### Example 1: License Audit Handler

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"

if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing Licenses for $OWNER"

echo "repo,visibility,archived,license,has_license"

TOTAL=0
WITH_LICENSE=0

while IFS= read -r row; do
  REPO_JSON=$(decode_repo_json "$row")
  
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VISIBILITY=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCHIVED=$(echo "$REPO_JSON" | jq -r '.isArchived')
  
  if [[ "$ARCHIVED" == "true" ]]; then
    continue
  fi
  
  ((TOTAL++))
  
  # Fetch license info
  LICENSE=$(gh api "/repos/$REPO/license" --jq '.license.name' 2>/dev/null || echo "none")
  
  HAS_LICENSE="false"
  if [[ "$LICENSE" != "none" && "$LICENSE" != "null" ]]; then
    HAS_LICENSE="true"
    ((WITH_LICENSE++))
  fi
  
  echo "$REPO,$VISIBILITY,$ARCHIVED,$LICENSE,$HAS_LICENSE"
  
done < <(get_repos "$OWNER")

cat >&2 <<EOF
{
  "handler": "license_audit",
  "total": $TOTAL,
  "with_license": $WITH_LICENSE
}
EOF

log_success "License audit completed"
```

### Example 2: README Quality Handler

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"

if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing README Quality for $OWNER"

echo "repo,visibility,archived,has_readme,readme_length,has_description"

TOTAL=0
WITH_README=0
WITH_DESC=0

while IFS= read -r row; do
  REPO_JSON=$(decode_repo_json "$row")
  
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  VISIBILITY=$(echo "$REPO_JSON" | jq -r '.visibility')
  ARCHIVED=$(echo "$REPO_JSON" | jq -r '.isArchived')
  
  if [[ "$ARCHIVED" == "true" ]]; then
    continue
  fi
  
  ((TOTAL++))
  
  # Check README
  README_CONTENT=$(gh api "/repos/$REPO/readme" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || echo "")
  README_LENGTH=${#README_CONTENT}
  
  HAS_README="false"
  if [[ $README_LENGTH -gt 0 ]]; then
    HAS_README="true"
    ((WITH_README++))
  fi
  
  # Check description
  DESCRIPTION=$(gh repo view "$REPO" --json description --jq '.description' 2>/dev/null || echo "")
  HAS_DESC="false"
  if [[ -n "$DESCRIPTION" && "$DESCRIPTION" != "null" ]]; then
    HAS_DESC="true"
    ((WITH_DESC++))
  fi
  
  echo "$REPO,$VISIBILITY,$ARCHIVED,$HAS_README,$README_LENGTH,$HAS_DESC"
  
done < <(get_repos "$OWNER")

cat >&2 <<EOF
{
  "handler": "readme_quality",
  "total": $TOTAL,
  "with_readme": $WITH_README,
  "with_description": $WITH_DESC
}
EOF

log_success "README quality audit completed"
```

---

## Testing Your Handler

### Unit Testing

```bash
# Test with your account
./handlers/my_custom_handler.sh YOUR_OWNER

# Verify CSV output is valid
./handlers/my_custom_handler.sh YOUR_OWNER | head -5

# Verify JSON statistics are valid
./handlers/my_custom_handler.sh YOUR_OWNER 2>&1 >/dev/null | jq .
```

### Integration Testing

```bash
# Add handler to master script and run
./scripts/audit_master.sh YOUR_OWNER reports

# Check reports include your handler data
cat reports/github_security_audit_report_*.md
```

---

## Common Patterns

### Pattern 1: Checking Feature Enabled

```bash
FEATURE_ENABLED=$(gh api "/repos/$REPO" --jq '.has_feature' 2>/dev/null || echo "false")
```

### Pattern 2: Handling API Errors

```bash
if ! API_RESPONSE=$(gh api "/repos/$REPO/endpoint" 2>/dev/null); then
  log_warn "Failed to fetch data for $REPO"
  echo "$REPO,$VISIBILITY,$ARCHIVED,error,error"
  continue
fi
```

### Pattern 3: Complex Data Extraction

```bash
# Fetch and parse complex JSON
WORKFLOWS=$(gh api "/repos/$REPO/actions/workflows" --jq '.workflows[] | select(.name | contains("Security")) | .name' 2>/dev/null || echo "")

if [[ -n "$WORKFLOWS" ]]; then
  HAS_SECURITY_WORKFLOW="true"
else
  HAS_SECURITY_WORKFLOW="false"
fi
```

---

## Debugging Tips

### Enable Debug Mode

```bash
# Run with bash debug flag
bash -x ./handlers/my_custom_handler.sh YOUR_OWNER

# Add debug output in handler
set -x  # Enable debug output
set +x  # Disable debug output
```

### Check API Responses

```bash
# Test API calls directly
gh api "/repos/OWNER/REPO/endpoint" | jq .

# Check rate limit
gh api rate_limit
```

### Validate Output

```bash
# Validate CSV
./handlers/my_custom_handler.sh YOUR_OWNER | csvlint

# Validate JSON stats
./handlers/my_custom_handler.sh YOUR_OWNER 2>&1 >/dev/null | jq empty
```

---

## Next Steps

- Review existing handlers in `handlers/` directory
- Check [[API Reference]] for available functions
- Read [[Architecture]] for system design
- See [[Contributing]] for contribution guidelines

---

**Last Updated:** March 4, 2026
