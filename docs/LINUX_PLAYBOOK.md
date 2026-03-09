# Linux Command Playbook - Smart Patterns & Best Practices

A practical guide to efficient Linux command usage, temporary file management, and bash scripting patterns used in production environments.

---

## Table of Contents

1. [Temporary File Management](#temporary-file-management)
2. [Command Chaining & Pipes](#command-chaining--pipes)
3. [File Operations](#file-operations)
4. [Data Processing](#data-processing)
5. [Safety Patterns](#safety-patterns)
6. [GitHub CLI Patterns](#github-cli-patterns)
7. [Script Best Practices](#script-best-practices)

---

## Temporary File Management

### Create Safe Temporary Files

```bash
# Create unique temp file (recommended)
tmpfile=$(mktemp)
echo "data" > "$tmpfile"
# Use it...
rm -f "$tmpfile"

# Create temp file with specific extension
tmpfile=$(mktemp --suffix=.json)

# Create temp directory
tmpdir=$(mktemp -d)
cd "$tmpdir"
# Work in it...
rm -rf "$tmpdir"
```

### Auto-Cleanup with Trap

```bash
#!/bin/bash
# Cleanup automatically on script exit (success or failure)

TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

# Now use $TEMP_DIR freely
# It will be deleted when script exits for ANY reason
```

### Cleanup Patterns Used in This Project

```bash
# Pattern 1: Manual cleanup after use
payload_file=$(mktemp)
jq -n --arg key "value" '{key:$key}' > "$payload_file"
gh api /endpoint --input "$payload_file"
rm -f "$payload_file"  # Clean up immediately after use

# Pattern 2: Reusable temp for multiple operations
tmpfile=$(mktemp)
for item in $LIST; do
  process "$item" > "$tmpfile"
  upload "$tmpfile"
done
rm -f "$tmpfile"

# Pattern 3: System temp with auto-naming
# /tmp files are automatically cleaned by OS on reboot
# Use for short-lived data only
echo "data" > /tmp/myapp-$$-data.txt  # $$ = process ID
```

### Where to Store Temp Files

| Location | Use Case | Lifetime | Best For |
|---|---|---|---|
| `mktemp` | Script-managed temp files | Script duration | Sensitive data, JSON payloads |
| `/tmp/` | System-managed temp | Until reboot | Short cache, build artifacts |
| `~/.cache/` | User cache data | Manual cleanup | App caches, downloads |
| `/var/tmp/` | Persistent temp | Survives reboot | Large temporary data |

---

## Command Chaining & Pipes

### Operators

```bash
# && : Run next command ONLY if previous succeeds
command1 && command2 && command3

# || : Run next command ONLY if previous fails  
command1 || echo "Failed!"

# ; : Always run next command (regardless of exit code)
command1 ; command2

# | : Pipe output from one to next
command1 | command2 | command3
```

### Smart Patterns

```bash
# Check and create
[[ ! -d reports ]] && mkdir -p reports

# Try command, fallback if fails
gh api endpoint 2>/dev/null || echo "default"

# Multi-step with error handling
if gh api endpoint > output.json 2>&1; then
  jq . output.json
else
  echo "API call failed"
fi

# Chain with intermediate verification
./step1.sh && \
  echo "Step 1 done" && \
  ./step2.sh && \
  echo "Step 2 done" && \
  ./step3.sh

# Pipe with error capture
result=$(command 2>&1) || {
  echo "Error: $result"
  exit 1
}
```

### Pipeline Patterns from This Project

```bash
# Get, decode, filter in one line
gh api 'repos/owner/repo/contents/file.yml' \
  --jq '.content' | \
  tr -d '\n' | \
  base64 --decode

# List, process, filter
gh repo list owner --json name,visibility --limit 500 | \
  jq -r '.[] | select(.visibility == "public") | .name'

# Multi-stage data transformation
cat input.csv | \
  tail -n +2 | \
  while IFS=',' read -r col1 col2 col3; do
    echo "$col1 | $col2"
  done | \
  sort | \
  uniq
```

---

## File Operations

### Safe File Editing

```bash
# NEVER edit directly, use temp file pattern
original="config.yml"
tmpfile=$(mktemp)
sed 's/old/new/g' "$original" > "$tmpfile"
mv "$tmpfile" "$original"

# Backup before replace
cp important.conf important.conf.bak
sed -i.bak 's/old/new/g' important.conf  # Creates .bak automatically

# Test command before applying
sed 's/old/new/g' file.txt  # Preview
sed -i '' 's/old/new/g' file.txt  # Apply (macOS)
sed -i 's/old/new/g' file.txt  # Apply (Linux)
```

### Reading Files Line by Line

```bash
# Best: Use while loop with IFS
while IFS= read -r line; do
  echo "Processing: $line"
done < file.txt

# With custom delimiter (CSV)
while IFS=',' read -r col1 col2 col3; do
  echo "$col1: $col2"
done < data.csv

# Skip header line
tail -n +2 data.csv | while IFS=',' read -r col1 col2; do
  process "$col1"
done

# From command output (heredoc pattern)
while IFS= read -r REPO; do
  [[ -z "$REPO" ]] && continue
  echo "Processing: $REPO"
done <<< "$REPOS"
```

### File Content Extraction

```bash
# Get first N lines
head -n 10 file.txt

# Get last N lines  
tail -n 10 file.txt

# Skip first line (header), process rest
tail -n +2 file.csv

# Get lines 5-10
sed -n '5,10p' file.txt

# Extract between patterns
sed -n '/START/,/END/p' file.txt

# Count lines/words/chars
wc -l file.txt   # Lines
wc -w file.txt   # Words
wc -c file.txt   # Bytes
```

---

## Data Processing

### JQ Patterns for JSON

```bash
# Extract single field
echo '{"name":"value"}' | jq -r '.name'

# Filter array
echo '[{"id":1},{"id":2}]' | jq '.[] | select(.id > 1)'

# Build JSON from variables
jq -n \
  --arg key1 "value1" \
  --arg key2 "value2" \
  '{key1: $key1, key2: $key2}'

# Multiple fields
jq -n \
  --arg msg "Enable feature" \
  --arg content "$BASE64_CONTENT" \
  --arg sha "$SHA" \
  '{message: $msg, content: $content, sha: $sha}'

# Compact vs Pretty
jq -c .  # Compact (one line)
jq .     # Pretty (formatted)

# Array to CSV
jq -r '.[] | [.name, .value] | @csv'

# Conditional extraction
jq -r '.[] | select(.enabled == true) | .name'
```

### Text Processing with AWK

```bash
# Print specific columns
awk '{print $1, $3}' file.txt

# With custom delimiter
awk -F',' '{print $2}' data.csv

# Sum column
awk '{sum += $1} END {print sum}' numbers.txt

# Filter and print
awk '$3 > 100 {print $1, $3}' data.txt

# Pattern matching
awk '/ERROR/ {print $0}' logfile.txt
```

### Text Processing with SED

```bash
# Replace first occurrence
sed 's/old/new/' file.txt

# Replace all occurrences
sed 's/old/new/g' file.txt

# Replace in-place (with backup)
sed -i.bak 's/old/new/g' file.txt

# Delete lines matching pattern
sed '/pattern/d' file.txt

# Delete blank lines
sed '/^$/d' file.txt

# Insert line after pattern
sed '/pattern/a\new line' file.txt

# Multi-line replacement
sed '/pattern/{N;d;}' file.txt  # Delete pattern + next line
```

### Grep Patterns

```bash
# Basic search
grep "pattern" file.txt

# Case-insensitive
grep -i "pattern" file.txt

# Recursive search
grep -r "pattern" directory/

# Count matches
grep -c "pattern" file.txt

# Show line numbers
grep -n "pattern" file.txt

# Invert match (exclude lines)
grep -v "pattern" file.txt

# Extended regex
grep -E "pattern1|pattern2" file.txt

# Quiet mode (just exit code)
if grep -q "pattern" file.txt; then
  echo "Found"
fi
```

---

## Safety Patterns

### Error Handling in Scripts

```bash
#!/bin/bash
# Exit on error, undefined variable, pipe failure
set -euo pipefail

# Custom error handler
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Usage
[[ -z "$VAR" ]] && error_exit "VAR is required"
command || error_exit "Command failed"
```

### Variable Safety

```bash
# Always quote variables
rm "$file"           # Good
rm $file             # Bad (breaks with spaces)

# Check if variable is set
[[ -z "$VAR" ]] && echo "VAR is empty"
[[ -n "$VAR" ]] && echo "VAR has value"

# Default values
OUTPUT="${OUTPUT:-default_value}"
FILE="${1:-default.txt}"

# Fail if unset (with set -u)
echo "$REQUIRED_VAR"  # Exits if unset
```

### File/Directory Checks

```bash
# File exists
[[ -f "file.txt" ]] && echo "File exists"

# Directory exists
[[ -d "dir" ]] && echo "Directory exists"

# File is executable
[[ -x "script.sh" ]] && echo "Executable"

# File is not empty
[[ -s "file.txt" ]] && echo "File has content"

# Create only if missing
[[ ! -d "reports" ]] && mkdir -p reports

# Safe removal
[[ -f "$tmpfile" ]] && rm -f "$tmpfile"
```

### Command Success Checks

```bash
# Check exit code
if command; then
  echo "Success"
else
  echo "Failed"
fi

# Capture output and check
if output=$(command 2>&1); then
  echo "Got: $output"
else
  echo "Error: $output"
fi

# Silent check
if command >/dev/null 2>&1; then
  echo "Command succeeded"
fi
```

---

## GitHub CLI Patterns

### API Calls

```bash
# GET request
gh api repos/owner/repo

# POST with JSON
gh api repos/owner/repo/issues -f title="Issue" -f body="Description"

# PUT file content (update)
gh api -X PUT repos/owner/repo/contents/file.txt \
  -f message="Update" \
  -f content="$(base64 < file.txt)"

# With JQ processing
gh api repos/owner/repo --jq '.name'

# Error handling
if gh api endpoint 2>/dev/null; then
  echo "Success"
else
  echo "API call failed"
fi
```

### Common Workflows from This Project

```bash
# Get file from repo
gh api 'repos/owner/repo/contents/path/file.yml?ref=main' \
  --jq '.content' | \
  tr -d '\n' | \
  base64 --decode

# List repos with filter
gh repo list owner \
  --json nameWithOwner,isArchived,visibility \
  --limit 500 | \
  jq -r '.[] | select(.isArchived == false) | .nameWithOwner'

# Create PR
gh pr create \
  --base main \
  --head feature-branch \
  --title "Feature: New capability" \
  --body "Description"

# Merge PR
gh pr merge 3 --squash --delete-branch

# Check workflow runs
gh run list --workflow workflow.yml --limit 5

# Get specific run logs
gh run view RUN_ID --log-failed
```

### Batch Operations

```bash
# Pattern: Process all repos
REPOS=$(gh repo list owner --json nameWithOwner --jq '.[].nameWithOwner')

while IFS= read -r REPO; do
  [[ -z "$REPO" ]] && continue
  
  echo "Processing: $REPO"
  
  # Do work on each repo
  gh api "repos/$REPO/topics" --jq '.names[]'
  
done <<< "$REPOS"
```

---

## Script Best Practices

### Script Template

```bash
#!/usr/bin/env bash
#############################################################################
# Script: script_name.sh
# Description: What this script does
# Usage: ./script_name.sh <arg1> <arg2>
#############################################################################

set -euo pipefail

# Script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source library if exists
[[ -f "$SCRIPT_DIR/lib/common.sh" ]] && source "$SCRIPT_DIR/lib/common.sh"

# Configuration
ARG1="${1:-}"
ARG2="${2:-default_value}"

# Validate inputs
if [[ -z "$ARG1" ]]; then
  echo "Usage: $0 <arg1> [arg2]" >&2
  exit 1
fi

# Cleanup on exit
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

#############################################################################
# Main Logic
#############################################################################

echo "Starting..."

# Your code here

echo "Done."
exit 0
```

### Logging Functions

```bash
# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

# Usage
log_info "Processing file..."
log_success "File processed successfully"
log_error "Failed to process file"
log_warn "Warning: Rate limit approaching"
```

### Progress Indicators

```bash
# Simple counter
TOTAL=100
for i in $(seq 1 $TOTAL); do
  echo -ne "Progress: $i/$TOTAL\r"
  # Work...
done
echo ""

# With percentage
CURRENT=0
TOTAL=100
while [[ $CURRENT -lt $TOTAL ]]; do
  PERCENT=$((CURRENT * 100 / TOTAL))
  echo -ne "Progress: ${PERCENT}%\r"
  ((CURRENT++))
done
echo ""

# Spinner (for long-running commands)
spin() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\\'
  while ps -p $pid > /dev/null 2>&1; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Usage
long_command &
spin $!
```

### Parallel Execution

```bash
# Run commands in background
for item in $ITEMS; do
  process "$item" &
done
wait  # Wait for all background jobs

# With limited parallelism
MAX_PARALLEL=4
count=0

for item in $ITEMS; do
  process "$item" &
  ((count++))
  
  if [[ $count -ge $MAX_PARALLEL ]]; then
    wait -n  # Wait for any one job to finish
    ((count--))
  fi
done
wait  # Wait for remaining jobs
```

---

## Real-World Examples from This Project

### Example 1: Clone, Edit, Commit, Push

```bash
# Clone repo to temp location
WORKDIR=/tmp/repo-fix-$$
gh repo clone owner/repo "$WORKDIR" -- -q

cd "$WORKDIR"

# Make changes with sed
sed -i '' 's|old-version@v2|new-version@v3|g' .github/workflows/ci.yml

# Stage, commit, push
git add .github/workflows/ci.yml
git commit -m "Update workflow to v3"
git push origin main

# Cleanup
cd -
rm -rf "$WORKDIR"
```

### Example 2: Batch Repo Updates with PR Flow

```bash
#!/bin/bash
set -euo pipefail

OWNER="$1"
REPOS=$(gh repo list "$OWNER" --json nameWithOwner --jq '.[].nameWithOwner')

while IFS= read -r REPO; do
  [[ -z "$REPO" ]] && continue
  
  echo "Processing: $REPO"
  
  # Get default branch
  DEFAULT_BRANCH=$(gh api "repos/$REPO" --jq '.default_branch')
  
  # Create feature branch
  BRANCH="fix/update-workflow-$(date +%s)"
  DEFAULT_SHA=$(gh api "repos/$REPO/git/ref/heads/$DEFAULT_BRANCH" --jq '.object.sha')
  
  gh api "repos/$REPO/git/refs" -X POST \
    -f ref="refs/heads/$BRANCH" \
    -f sha="$DEFAULT_SHA"
  
  # Update file
  CONTENT=$(cat <<'EOF'
name: CI
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Updated"
EOF
)
  
  gh api "repos/$REPO/contents/.github/workflows/ci.yml" -X PUT \
    -f message="Update CI workflow" \
    -f content="$(echo "$CONTENT" | base64)" \
    -f branch="$BRANCH"
  
  # Create PR
  gh pr create -R "$REPO" \
    -B "$DEFAULT_BRANCH" \
    -H "$BRANCH" \
    -t "Update CI workflow" \
    -b "Automated update"
  
done <<< "$REPOS"
```

### Example 3: Audit with Report Generation

```bash
#!/bin/bash
set -euo pipefail

OWNER="$1"
REPORT_DIR="reports"
TS=$(date +%Y%m%d_%H%M%S)

mkdir -p "$REPORT_DIR"
CSV_FILE="$REPORT_DIR/audit_${OWNER}_${TS}.csv"
MD_FILE="$REPORT_DIR/audit_${OWNER}_${TS}.md"

# CSV header
echo "repo,status,finding" > "$CSV_FILE"

# Process repos
TOTAL=0
ISSUES=0

REPOS=$(gh repo list "$OWNER" --json nameWithOwner --jq '.[].nameWithOwner')

while IFS= read -r REPO; do
  [[ -z "$REPO" ]] && continue
  
  ((TOTAL++))
  
  # Check for workflow
  if gh api "repos/$REPO/contents/.github/workflows" >/dev/null 2>&1; then
    status="ok"
    finding="Workflow exists"
  else
    status="missing"
    finding="No workflow found"
    ((ISSUES++))
  fi
  
  echo "$REPO,$status,$finding" >> "$CSV_FILE"
  
done <<< "$REPOS"

# Generate markdown report
{
  echo "# Audit Report"
  echo ""
  echo "- Owner: $OWNER"
  echo "- Date: $(date)"
  echo "- Total: $TOTAL"
  echo "- Issues: $ISSUES"
  echo ""
  echo "## Results"
  echo ""
  echo "| Repo | Status | Finding |"
  echo "|---|---|---|"
  tail -n +2 "$CSV_FILE" | while IFS=',' read -r repo status finding; do
    echo "| $repo | $status | $finding |"
  done
} > "$MD_FILE"

echo "Reports generated:"
echo "- $CSV_FILE"
echo "- $MD_FILE"
```

---

## Quick Reference Card

### Most Used Patterns

```bash
# Safe temp file
tmpfile=$(mktemp) && trap "rm -f '$tmpfile'" EXIT

# Check if command exists
command -v gh >/dev/null 2>&1 || { echo "gh not found"; exit 1; }

# Get directory of script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Process list safely
while IFS= read -r item; do
  [[ -z "$item" ]] && continue
  echo "$item"
done <<< "$LIST"

# JSON from variables
jq -n --arg k1 "v1" --arg k2 "v2" '{k1:$k1, k2:$k2}'

# Decode base64 from API
gh api endpoint --jq '.content' | tr -d '\n' | base64 --decode

# Conditional execution
[[ -f file.txt ]] && echo "exists" || echo "missing"

# Safe variable expansion
rm -f "${TMPFILE}"  # Good
rm -f "$TMPFILE"    # OK
rm -f $TMPFILE      # Bad

# Exit on any error
set -euo pipefail
```

---

## Common Gotchas & Fixes

### Problem: Word splitting breaks paths with spaces

```bash
# BAD
file="my document.txt"
cat $file  # Tries to cat "my" and "document.txt"

# GOOD
cat "$file"
```

### Problem: Command output has trailing newline

```bash
# BAD
content=$(cat file.txt)  # Includes trailing newline

# GOOD
content=$(cat file.txt | tr -d '\n')
# OR
content=$(< file.txt tr -d '\n')
```

### Problem: Sed differs between macOS and Linux

```bash
# macOS requires '' after -i
sed -i '' 's/old/new/' file.txt

# Linux doesn't
sed -i 's/old/new/' file.txt

# Portable solution
tmpfile=$(mktemp)
sed 's/old/new/' file.txt > "$tmpfile"
mv "$tmpfile" file.txt
```

### Problem: Process runs in subshell, variables lost

```bash
# BAD - pipe creates subshell
echo "data" | while read line; do
  count=$((count + 1))
done
echo $count  # Still 0!

# GOOD - use process substitution or heredoc
while read line; do
  count=$((count + 1))
done < <(echo "data")
echo $count  # Works!
```

---

## Additional Resources

- **Shell Check**: https://www.shellcheck.net/ (validate your scripts)
- **Bash Manual**: https://www.gnu.org/software/bash/manual/
- **JQ Manual**: https://stedolan.github.io/jq/manual/
- **GitHub CLI Manual**: https://cli.github.com/manual/

---

**Last Updated:** March 9, 2026  
**Maintained by:** SVETRI Project
