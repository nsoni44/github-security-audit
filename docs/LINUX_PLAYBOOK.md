# Linux Command Playbook - Smart Patterns & Best Practices

A practical guide to efficient Linux command usage, temporary file management, and bash scripting patterns used in production environments.

---

## Table of Contents

1. [Syntax & Symbols Reference](#syntax--symbols-reference)
2. [Temporary File Management](#temporary-file-management)
3. [Command Chaining & Pipes](#command-chaining--pipes)
4. [File Operations](#file-operations)
5. [Data Processing](#data-processing)
6. [Safety Patterns](#safety-patterns)
7. [GitHub CLI Patterns](#github-cli-patterns)
8. [Script Best Practices](#script-best-practices)

---

## Syntax & Symbols Reference

Understanding what each symbol means is crucial for mastering Linux commands.

### Special Variables

| Symbol | Name | Meaning | Example |
|---|---|---|---|
| `$` | Variable expansion | Access value of a variable | `echo $HOME` |
| `$0` | Script name | Name of the current script | `echo "Running: $0"` |
| `$1, $2, $3...` | Positional parameters | Command-line arguments | `./script.sh arg1 arg2` → `$1=arg1` |
| `$#` | Argument count | Number of arguments passed | `if [[ $# -eq 0 ]]; then` |
| `$$` | Process ID | PID of current script | `tmpfile=/tmp/app-$$.tmp` |
| `$?` | Exit status | Return code of last command | `echo $?` (0=success) |
| `$!` | Background PID | PID of last background job | `command & echo $!` |
| `$@` | All arguments | All positional parameters | `for arg in "$@"; do` |
| `$*` | All arguments (single) | All params as one string | Less common than `$@` |

**W

**What `mktemp` does:**
- Creates file with random name like `/tmp/tmp.xYz123AbC`
- Guarantees unique name (prevents conflicts)
- Sets restrictive permissions (only you can read/write)
- Returns the path so you can reference it

**Why `mktemp` over manual names:**
- Manual: `/tmp/myfile.txt` → Multiple runs conflict, security risk
- `mktemp`: `/tmp/tmp.abc123` → Unique every time, securehy use these?**
- Variables let you reuse values and make scripts dynamic
- Process ID (`$$`) ensures unique temp file names
- Exit codes (`$?`) enable proper error handling
- Positional parameters make scripts flexible and reusable

### Redirection Operators

| Symbol | Name | Meaning | Example |
|---|---|---|---|
| `>` | Output redirect | Write stdout to file (overwrite) | `echo "text" > file.txt` |
| `>>` | Append redirect | Append stdout to file | `echo "more" >> file.txt` |
| `<` | Input redirect | Read from file as stdin | `command < input.txt` |
| `2>` | Error redirect | Redirect stderr to file | `command 2> errors.txt` |
| `2>&1` | Combine streams | Redirect stderr to stdout | `command > all.txt 2>&1` |
| `&>` | Both to file | Redirect both stdout+stderr | `command &> output.txt` |
| `|` | Pipe | Send stdout to next command | `cat file \| grep pattern` |
| `\|&` | Pipe both | Send stdout+stderr to next | `command \|& grep error` |

**Understanding `2>&1`:**
- `1` = stdout (standard output)
- `2` = stderr (standard error)
- `2>&1` means "redirect stderr (2) to wherever stdout (1) is going"
- Order matters: `command > file.txt 2>&1` (correct) vs `command 2>&1 > file.txt` (wrong)

**Why separate stdout and stderr?**
- stdout = normal output (data you want)
- stderr = error messages (diagnostics)
- Separating them lets you process data and errors differently

### File Test Operators

| Operator | Meaning | Example |
|---|---|---|
| `-f` | File exists and is regular file | `[[ -f file.txt ]]` |
| `-d` | Directory exists | `[[ -d /path/dir ]]` |
| `-e` | Path exists (file or dir) | `[[ -e /path ]]` |
| `-s` | File exists and not empty | `[[ -s file.txt ]]` |
| `-x` | File is executable | `[[ -x script.sh ]]` |
| `-r` | File is readable | `[[ -r file.txt ]]` |
| `-w` | File is writable | `[[ -w file.txt ]]` |
| `-L` | Path is symbolic link | `[[ -L /path/link ]]` |

**Why test files?**
- Prevent errors from operating on non-existent files
- Check permissions before attempting operations
- Make scripts defensive and robust

### Command Options - Common Flags

| Flag | Meaning | Example Commands |
|---|---|---|
| `-r` | Recursive (process dirs) | `rm -r`, `cp -r`, `chmod -r` |
| `-f` | Force (no confirm) | `rm -f`, `cp -f` |
| `-v` | Verbose (show details) | `cp -v`, `rm -v` |
| `-i` | Interactive (ask confirm) | `rm -i`, `mv -i` |
| `-n` | Dry run / Line numbers | `sed -n`, `grep -n` |
| `-a` | All (include hidden) | `ls -a` |
| `-l` | Long format / Follow links | `ls -l`, `cp -l` |
| `-h` | Human readable / Help | `du -h`, `command -h` |

**Understanding `rm -rf`:**
- `rm` = remove files/directories
- `-r` = recursive (delete directories and contents)
- `-f` = force (no confirmation, ignore errors)
- **DANGER**: `rm -rf /` would delete everything! Always double-check paths.

**Why use flags?**
- Modify command behavior for specific needs
- `-v` helps debug by showing what's happening
- `-f` automates by skipping confirmations
- `-r` enables operating on directory trees

### String Operations

| Operator | Meaning | Example |
|---|---|---|
| `${var}` | Variable expansion | `echo "${HOME}/file"` |
| `${var:-default}` | Default if unset | `${PORT:-8080}` |
| `${var:?error}` | Error if unset | `${REQUIRED:?missing}` |
| `${var#pattern}` | Remove prefix | `${file#*/}` removes up to / |
| `${var%pattern}` | Remove suffix | `${file%.txt}` removes .txt |
| `${var/old/new}` | Replace first | `${text/foo/bar}` |
| `${var//old/new}` | Replace all | `${text//foo/bar}` |

**Why use parameter expansion?**
- Provide defaults for missing config values
- Manipulate strings without external commands
- Make scripts more robust to missing inputs

### Logical Operators

| Operator | Meaning | Example |
|---|---|---|
| `&&` | AND - run if previous succeeded | `cmd1 && cmd2` |
| `\|\|` | OR - run if previous failed | `cmd1 \|\| cmd2` |
| `;` | Sequential - always run next | `cmd1 ; cmd2` |
| `!` | NOT - negate condition | `if ! command; then` |
| `-a` | AND (in test) | `[[ -f file -a -r file ]]` |
| `-o` | OR (in test) | `[[ -f file -o -d dir ]]` |

**Why chain commands?**
- Execute multi-step operations atomically
- Handle errors gracefully with fallbacks
- Write one-liners instead of full scripts

### Quoting & Escaping

| Type | Purpose | Example |
|---|---|---|
| `"double"` | Allow variable expansion | `echo "$HOME"` → `/home/user` |
| `'single'` | Literal (no expansion) | `echo '$HOME'` → `$HOME` |
| `` `backtick` `` | Command substitution (old) | `` file=`date` `` |
| `$(command)` | Command substitution (new) | `file=$(date +%Y%m%d)` |
| `\` | Escape character | `echo \$HOME` → `$HOME` |

**Critical quoting rule:**
- Always quote variables: `"$var"` not `$var`
- Prevents word splitting and glob expansion
- Example: `file="my doc.txt"` → `rm $file` tries to delete `my` and `doc.txt`

---

## Temporary File Management

### Why Use Temporary Files?

**Problem:** Many operations need intermediate storage but leave pollution behind.

**Real scenarios:**
1. **Building JSON payloads** for API calls (don't want to escape quotes in command line)
2. **Processing large data** that doesn't fit in variables or pipes
3. **Atomic file updates** (edit temp, then move to final location)
4. **Concurrent operations** where each needs unique workspace
5. **Sensitive data** that shouldn't live in permanent storage

**Why not just use regular files?**
- Temp files auto-cleanup (with proper patterns)
- Unique names prevent conflicts
- System manages cleanup on reboot for `/tmp`
- Clear intent: "this is temporary"

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


**What `trap` does:**
- Registers a command to run on certain signals
- `EXIT` signal = script ending (any reason: success, error, Ctrl+C)
- Guarantees cleanup even if script crashes

**Why use `trap`:**
- Manual cleanup: You might forget, or script exits early
- With `trap`: Cleanup happens automatically, no matter what
- Example: Script crashes at line 50, but temp files still get cleaned up

**Syntax breakdown:**
- `trap "command" SIGNAL`
- `"rm -rf '$TEMP_DIR'"` = command to run (quoted to preserve variable)
- `EXIT` = when to run it (could also be `INT` for Ctrl+C, `ERR` for errors)
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

**Why different locations?**
- `/tmp/` = Fast (often RAM disk), auto-cleaned, but lost on reboot
- `/var/tmp/` = Disk-based, survives reboot, for larger files
- `~/.cache/` = Per-user, survives reboot, for app-specific caches
- `mWhy Chain Commands?

**Problems solved:**
1. **Multi-step workflows**: Install → Configure → Start (only if previous worked)
2. **Fallback logic**: Try primary, use backup if it fails
3. **Data pipelines**: Transform data through multiple stages
4. **One-liners**: Avoid writing full scripts for simple tasks

**Theory:**
Every command returns an **exit code**:
- `0` = success
- `1-255` = failure (different numbers = different errors)

Chaining operators use these codes to decide what runs next.

### Operators

```bash
# && : Run next command ONLY if previous succeeds (exit code = 0)
command1 && command2 && command3

# || : Run next command ONLY if previous fails (exit code != 0)
command1 || echo "Failed!"

# ; : Always run next command (regardless of exit code)
command1 ; command2

# | : Pipe output from one to next (connects stdout to stdin)
command1 | command2 | command3
```

**Mental model for `&&`:**
- "Do A, and if that works, then do B"
- Like: "Cook dinner && Serve it" (don't serve if cooking failed!)

**Mental model for `||`:**
- "Try A, or if that fails, do B instead"
- Like: "Use WiFi || Use cellular data" (fallback if primary unavailable)

**Mental model for `|` (pipe):**
- "Take output of A and feed it as input to B"
- Like: "Factory line: Cut wood | Sand it | Paint it"se for short-lived data only
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
Why Safe File Editing Matters

**Problem:** Direct file editing can corrupt data if something fails mid-write.

**Scenario:**
```bash
# DANGEROUS
sed -i 's/old/new/g' important.conf
# If sed crashes half-way, file is corrupted!
```

**Why in-place editing is risky:**
1. Power loss mid-write → Partial file, data lost
2. Disk full mid-write → Truncated file
3. Bug in sed pattern → Malformed output written
4. No undo (original is gone)

**Solution: Atomic updates via temp file**
1. Edit to temp file
2. Verify temp file is good
3. Atomically move temp to replace original
**Why not just `cat file.txt`?**
- `cat` dumps entire file (memory issue for huge files)
- Can't process each line individually
- No line-by-line logic

**Why while loop?**
- Reads one line at a time (memory efficient)
- Can process/transform each line
- Can make decisions per line

```bash
# Best: Use while loop with IFS
while IFS= read -r line; do
  echo "Processing: $line"
done < file.txt
```

**Syntax breakdown:**
- `IFS=` = Don't split on spaces (preserve whitespace)
- `read -r` = Raw mode (don't interpret backslashes)
- `< file.txt` = Redirect file as input to while loop
# SAFE: Edit via temp file
original="config.yml"
tmpfile=$(mktemp)
sed 's/old/new/g' "$original" > "$tmpfile"
# Optionally: validate "$tmpfile" here
mv "$tmpfile" "$original"  # 'mv' is atomic - all or nothingf fails
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
Why Use Specialized Tools?

**Problem:** Working with structured data (JSON, CSV, logs) in bash is painful.

**Why not just `grep` and `cut`?**
- JSON isn't line-based (nested structures)
- CSV has quoting and escaping rules
- Pattern matching on structured data needs schema awareness

**Solution:** Use domain-specific tools:
- **jq** = JSON processor (like sed/awk but for JSON)
- **awk** = Column-oriented data (great for space/tab delimited)
- **sed** = Stream editor (line-by-line text transformation)
- **grep** = Pattern matching (find lines with patterns)

### JQ Patterns for JSON

**Why jq?**
- Safely parse JSON (handles escaping, nesting)
- Extract fields by path notation (`.field.subfield`)
- Filter arrays, transform data
- Build new JSON from variables

```bash
# Extract single field
echo '{"name":"value"}' | jq -r '.name'
```

**Syntax breakdown:**
- `jq` = JSON query tool
- `-r` = Raw output (no quotes around strings)
- `.name` = Path to field (like object.name in JavaScript)
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
**What is sed?**
- "Stream EDitor" - edits text as it flows through
- Line-by-line processing
- No need to load entire file in memory

**Why use sed?**
- Find and replace across files
- Delete lines matching patterns
- Insert/append text
- Fast for large files (streams data)

**Common pattern: `s/old/new/g`**
- `s` = substitute command
- `/old/` = pattern to find (can be regex)
- `/new/` = replacement text
- `/g` = global flag (all occurrences on line, not just first)

```bash
# Replace first occurrence per line
sed 's/old/new/' file.txt

# Replace all occurrences per line
sed 's/old/new/g' file.txt
```

**Why the flags matter:**
- No `g`: `"old old old"` → `"new old old"` (only first)
- With `g`: `"old old old"` → `"new new new"` (all)al" > "$tmpfile"
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
Why Scripts Need Safety Mechanisms

**Problem:** Bash scripts keep running even after errors!

**Dangerous default behavior:**
```bash
#!/bin/bash
rm important.txt      # Oops, typo - file doesn't exist
echo "File deleted"   # This still runs!
deploy_to_prod        # This runs too - disaster!
```

**Why this is bad:**
- Errors get buried in output
- Subsequent commands work with bad state
- Silent failures cause hard-to-debug issues

**Solution: Fail fast with `set` options**

### Error Handling in Scripts
**Why quoting matters:**

**Problem: Word splitting and globbing**

```bash
file="my document.txt"
rm $file    # Bash sees: rm my document.txt
            # Tries to delete TWO files: "my" and "document.txt"
            
rm "$file"  # Bash sees: rm "my document.txt"  
            # Deletes ONE file: "my document.txt"
```

**Another problem: Glob expansion**
```bash
pattern="*.txt"
echo $pattern    # Expands to: file1.txt file2.txt file3.txt
echo "$pattern"  # Prints literal: *.txt
```
**Why test before operating on files?**

**Problem: Operations fail silently or catastrophically**
```bash
# Without check
cat important.txt        # Error if doesn't exist, but script continues
rm -rf "$config_dir"     # Deletes wrong thing if variable empty!
```

**Solution: Defensive checks**
```bash
# Check first, act second
[[ -f important.txt ]] || { echo "Missing file!"; exit 1; }
[[ -n "$config_dir" ]] || { echo "Variable empty!"; exit 1; }
```

**Syntax: `[[ ... ]]` vs `[ ... ]`:**
- `[[ ]]` = Modern bash test (preferred)
- `[ ]` = POSIX test (compatible with old shells)
- `[[ ]]` supports `&&`, `||`, `<`, `>` inside
- `[[ ]]` doesn't need quotes as much
- Use `[[ ]]` in bash scripts

```bash
# File exists
[[ -f "file.txt" ]] && echo "File exists"

# Directory exists
[[ -d "dir" ]] && echo "Directory exists"
```

**Why these specific tests:**
- `-f` = regular file (not dir, not symlink)
- `-d` = directory
- `-e` = exists (any type)
- `-s` = exists and not empty (size > 0)ingle value
rm $file             # Bad - word splits on spaces/tabs/newlines
```

**Why `"$var"` instead of `$var`:**
- Preserves spaces, tabs, newlines
- Prevents glob expansion (*, ?, [])
- Prevents word splitting
- Shows intent: "this is one value"re
set -euo pipefail
```

**What each flag does:**

**`set -e`** (errexit):
- Exit immediately if any command fails (returns non-zero)
- Example: `rm missing.txt` → Script stops, doesn't continue

**`set -u`** (nounset):
- Treat undefined variables as errors
- Example: `echo $TYPO` → Error instead of silently printing blank

**`set -o pipefail`**:
- Pipe fails if ANY command in pipeline fails (not just last)
- Without: `failing_cmd | succeeding_cmd` → Success (only last checked)
- With: `failing_cmd | succeeding_cmd` → Failure (any failure triggers)

**Why all three together:**
- `-e` catches command failures
- `-u` catches typos and missing config
- `pipefail` catches errors in middle of pipelines
- Together: Scripts fail fast and loud, not silent and corrupt
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
