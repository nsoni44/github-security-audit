# API Reference

Function reference for the GitHub Security Audit common library.

---

## Overview

The `lib/common.sh` library provides shared utilities for all handlers. Source it in your scripts:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"
```

---

## Logging Functions

### `log_info(message)`

Display informational message in blue.

**Parameters:**
- `message` - Message to display

**Example:**
```bash
log_info "Starting audit for $OWNER"
# Output: [INFO] Starting audit for nsoni44
```

---

### `log_success(message)`

Display success message in green with checkmark.

**Parameters:**
- `message` - Message to display

**Example:**
```bash
log_success "Audit completed successfully"
# Output: [✓] Audit completed successfully
```

---

### `log_error(message)`

Display error message in red to stderr.

**Parameters:**
- `message` - Error message to display

**Example:**
```bash
log_error "Failed to access repository"
# Output: [ERROR] Failed to access repository
```

---

### `log_warn(message)`

Display warning message in yellow.

**Parameters:**
- `message` - Warning message to display

**Example:**
```bash
log_warn "Rate limit approaching"
# Output: [WARN] Rate limit approaching
```

---

## Prerequisite Checks

### `check_gh_installed()`

Check if GitHub CLI (`gh`) is installed.

**Returns:**
- `0` - gh is installed
- `1` - gh is not installed

**Example:**
```bash
if ! check_gh_installed; then
  exit 1
fi
```

---

### `check_gh_authenticated()`

Check if GitHub CLI is authenticated.

**Returns:**
- `0` - gh is authenticated
- `1` - gh is not authenticated

**Example:**
```bash
if ! check_gh_authenticated; then
  log_error "Please run: gh auth login"
  exit 1
fi
```

---

### `check_prerequisites()`

Check all prerequisites (gh installed, authenticated, jq available, etc.).

**Returns:**
- `0` - All prerequisites met
- `1` - One or more prerequisites missing

**Example:**
```bash
if ! check_prerequisites; then
  exit 1
fi
```

**Checks:**
- GitHub CLI (`gh`) installed
- GitHub CLI authenticated
- `jq` installed
- `date` command available

---

## Repository Functions

### `get_repos(owner)`

Fetch all repositories for an owner (user or organization).

**Parameters:**
- `owner` - GitHub username or organization name

**Returns:**
Base64-encoded JSON for each repository (one per line)

**Fields included:**
- `nameWithOwner` - Full repository name (owner/repo)
- `visibility` - PUBLIC or PRIVATE
- `isArchived` - true or false

**Example:**
```bash
while IFS= read -r row; do
  # Process each repository
  repo_json=$(decode_repo_json "$row")
  repo_name=$(echo "$repo_json" | jq -r '.nameWithOwner')
  echo "Processing: $repo_name"
done < <(get_repos "$OWNER")
```

**Notes:**
- Respects GitHub API rate limits
- Returns up to 500 repositories
- Output is Base64-encode for safe handling of special characters

---

### `decode_repo_json(base64_data)`

Decode Base64-encoded repository data to JSON.

**Parameters:**
- `base64_data` - Base64-encoded repository JSON

**Returns:**
Decoded JSON string

**Example:**
```bash
while IFS= read -r row; do
  repo_json=$(decode_repo_json "$row")
  
  name=$(echo "$repo_json" | jq -r '.nameWithOwner')
  visibility=$(echo "$repo_json" | jq -r '.visibility')
  archived=$(echo "$repo_json" | jq -r '.isArchived')
  
  echo "Repo: $name ($visibility, archived=$archived)"
done < <(get_repos "$OWNER")
```

---

## Directory Functions

### `ensure_report_dir(directory)`

Create directory if it doesn't exist.

**Parameters:**
- `directory` - Path to directory

**Returns:**
- `0` - Directory created or already exists
- Non-zero - Failed to create directory

**Example:**
```bash
ensure_report_dir "reports/audit_$(date +%Y%m%d)"
```

---

## Timestamp Functions

### `get_timestamp()`

Generate timestamp in format YYYYMMDD_HHMMSS.

**Returns:**
Timestamp string

**Example:**
```bash
TIMESTAMP=$(get_timestamp)
echo "Report generated at: $TIMESTAMP"
# Output: Report generated at: 20260304_213045
```

**Usage:**
- File naming: `report_${TIMESTAMP}.md`
- Unique identifiers
- Audit tracking

---

### `get_readable_date()`

Generate human-readable date string.

**Returns:**
Formatted date string (locale-dependent)

**Example:**
```bash
DATE=$(get_readable_date)
echo "Generated: $DATE"
# Output: Generated: Wed Mar  4 21:30:45 EET 2026
```

---

## Color Codes

Pre-defined color variables for terminal output:

| Variable | Color | Usage |
|----------|-------|-------|
| `$RED` | Red | Errors, failures |
| `$GREEN` | Green | Success, completion |
| `$YELLOW` | Yellow | Warnings, notices |
| `$BLUE` | Blue | Information |
| `$NC` | No Color | Reset to default |

**Example:**
```bash
echo -e "${GREEN}Success!${NC}"
echo -e "${RED}Error occurred${NC}"
```

---

## Usage Patterns

### Pattern 1: Basic Handler Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

OWNER="${1:?Owner parameter required}"

if ! check_prerequisites; then
  exit 1
fi

log_info "Starting audit for $OWNER"

# Main logic here

log_success "Audit completed"
```

### Pattern 2: Repository Iteration

```bash
TOTAL=0

while IFS= read -r row; do
  repo_json=$(decode_repo_json "$row")
  
  repo=$(echo "$repo_json" | jq -r '.nameWithOwner')
  visibility=$(echo "$repo_json" | jq -r '.visibility')
  archived=$(echo "$repo_json" | jq -r '.isArchived')
  
  # Skip archived repositories
  if [[ "$archived" == "true" ]]; then
    continue
  fi
  
  ((TOTAL++))
  
  # Process repository
  log_info "Processing $repo"
  
done < <(get_repos "$OWNER")

log_success "Processed $TOTAL repositories"
```

### Pattern 3: Error Handling

```bash
if ! check_prerequisites; then
  log_error "Prerequisites not met"
  exit 1
fi

if ! API_RESPONSE=$(gh api "/endpoint" 2>/dev/null); then
  log_error "API call failed"
  exit 1
fi

# Validate data
if [[ -z "$REQUIRED_FIELD" ]]; then
  log_warn "Missing required field, using default"
  REQUIRED_FIELD="default_value"
fi
```

### Pattern 4: Output Formatting

```bash
# CSV output to stdout
echo "repo,metric1,metric2"
echo "$REPO,$VALUE1,$VALUE2"

# JSON statistics to stderr
cat >&2 <<EOF
{
  "handler": "my_handler",
  "total": $TOTAL,
  "enabled": $ENABLED_COUNT
}
EOF
```

---

## Environment Variables

Variables exported by common.sh:

| Variable | Description |
|----------|-------------|
| `RED` | Red color code |
| `GREEN` | Green color code |
| `YELLOW` | Yellow color code |
| `BLUE` | Blue color code |
| `NC` | No color (reset) |

All functions are also exported and available in subshells.

---

## Best Practices

### ✅ DO

- Always source `common.sh` at script start
- Use `check_prerequisites()` before API calls
- Use logging functions for user feedback
- Handle errors gracefully
- Use `decode_repo_json()` for safe JSON parsing
- Quote variables: `"$VARIABLE"`

### ❌ DON'T

- Don't parse JSON with regex/sed/awk
- Don't ignore return codes
- Don't assume commands exist
- Don't use color codes without `$NC` reset
- Don't output to stderr except for statistics

---

## Error Codes

Standard exit codes:

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Missing prerequisites |
| `126` | Command cannot execute |
| `127` | Command not found |
| `130` | Script terminated by Ctrl+C |

---

## GitHub API Helpers

While not in `common.sh`, these `gh` CLI patterns are commonly used:

### Fetch Repository Data

```bash
gh api "/repos/$OWNER/$REPO" --jq '.field'
```

### List Resources

```bash
gh api "/repos/$OWNER/$REPO/branches" --jq '.[].name'
```

### Paginated Results

```bash
gh api --paginate "/repos/$OWNER/$REPO/issues"
```

### Error Handling

```bash
if gh api "/repos/$OWNER/$REPO" 2>/dev/null; then
  echo "Success"
else
  echo "Failed"
fi
```

---

## Examples

See [[Handler Development]] for complete handler examples using these functions.

---

## Related Documentation

- [[Handler Development]] - Creating custom handlers
- [[Architecture]] - System design
- [[Usage Guide]] - General usage

---

**Last Updated:** March 4, 2026
