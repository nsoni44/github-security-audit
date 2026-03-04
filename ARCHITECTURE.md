# GitHub Security Audit - Modular Architecture

## Project Structure

```
.
├── scripts/
│   ├── github_security_audit.sh      # Legacy script (original all-in-one)
│   └── audit_master.sh               # NEW: Master orchestrator script
├── handlers/                         # NEW: Individual audit handlers
│   ├── secret_scanning.sh            # Audits secret scanning & push protection
│   ├── dependabot.sh                 # Audits Dependabot configurations
│   ├── branch_protection.sh          # Audits branch protection rules
│   ├── code_scanning.sh              # Audits code scanning (GHAS)
│   └── repo_config.sh                # Audits repository configurations
├── lib/                              # NEW: Shared utilities and libraries
│   └── common.sh                     # Common functions and utilities
├── templates/                        # NEW: Report templates (future use)
├── reports/                          # Generated audit reports
│   ├── github_security_audit_combined_*.csv     # Combined security metrics
│   ├── github_security_audit_report_*.md        # Markdown report
│   └── github_security_audit_stats_*.json       # Statistics JSON
└── README.md                         # This file
```

## Architecture Overview

### Master Script (`audit_master.sh`)

The master orchestrator script:
- Coordinates execution of all security handlers
- Aggregates results from multiple handlers
- Generates unified reports in multiple formats
- Handles error management and logging
- Supports email notifications

**Usage:**
```bash
./scripts/audit_master.sh [OWNER] [REPORT_DIR] [EMAIL_TO]
```

**Parameters:**
- `OWNER`: GitHub username/organization (default: `nsoni44`)
- `REPORT_DIR`: Directory for report output (default: `reports`)
- `EMAIL_TO`: Email address for notifications (optional)

**Example:**
```bash
./scripts/audit_master.sh nsoni44 reports user@example.com
```

### Handler Scripts (`handlers/`)

Each handler focuses on a specific security aspect:

#### 1. **secret_scanning.sh**
Audits secret scanning and push protection features.

**Metrics:**
- Secret scanning enabled/disabled
- Push protection enabled/disabled

**Output:** CSV format with columns:
- repo, visibility, archived, secret_scanning, push_protection

---

#### 2. **dependabot.sh**
Audits Dependabot security and version update configurations.

**Metrics:**
- Dependabot security updates status
- Dependabot version updates configuration

**Output:** CSV format with columns:
- repo, visibility, archived, dependabot_security_updates, dependabot_version_updates

---

#### 3. **branch_protection.sh**
Audits branch protection rules on default branches.

**Metrics:**
- Branch protection enabled/disabled
- Required reviews configured
- Required status checks

**Output:** CSV format with columns:
- repo, visibility, archived, default_branch, branch_protection_enabled, requires_reviews, requires_status_checks

---

#### 4. **code_scanning.sh**
Audits code scanning (GitHub Advanced Security) and CodeQL workflows.

**Metrics:**
- Code scanning enabled/disabled
- CodeQL configured
- Active security alerts

**Output:** CSV format with columns:
- repo, visibility, archived, code_scanning_enabled, codeql_configured, has_alerts

---

#### 5. **repo_config.sh**
Audits repository-level configurations and settings.

**Metrics:**
- Has description
- Has homepage
- Wiki enabled
- Pages enabled
- Forking allowed
- Downloads allowed

**Output:** CSV format with columns:
- repo, visibility, archived, has_description, has_homepage, has_wiki, has_pages, allow_fork, allow_downloads

---

### Common Library (`lib/common.sh`)

Shared utilities used by all handlers:

**Logging Functions:**
- `log_info()` - Information messages (blue)
- `log_success()` - Success messages (green)
- `log_error()` - Error messages (red)
- `log_warn()` - Warning messages (yellow)

**Validation Functions:**
- `check_gh_installed()` - Verify GitHub CLI installed
- `check_gh_authenticated()` - Verify GitHub CLI authentication
- `check_prerequisites()` - Check all required tools

**Utility Functions:**
- `get_repos(OWNER)` - Fetch list of repos for owner
- `decode_repo_json()` - Decode Base64 encoded repo data
- `ensure_report_dir(DIR)` - Create report directory
- `get_timestamp()` - Get formatted timestamp
- `get_readable_date()` - Get human-readable date

---

## Reports Generated

### 1. **Combined CSV Report**
`github_security_audit_combined_[OWNER]_[TIMESTAMP].csv`

Combines all security metrics in structured CSV format with columns from all handlers.

### 2. **Markdown Report**
`github_security_audit_report_[OWNER]_[TIMESTAMP].md`

Human-readable report with:
- Summary statistics with JSON formatting
- Detailed results per handler
- Formatted tables for easy viewing
- Suitable for documentation and sharing

### 3. **Statistics JSON**
`github_security_audit_stats_[OWNER]_[TIMESTAMP].json`

Machine-readable JSON containing:
- Metadata (owner, timestamp, total repos)
- Statistics from each handler
- Useful for automation and integration

---

## Usage Examples

### Run Full Audit
```bash
./scripts/audit_master.sh nsoni44 reports
```

### Run Full Audit with Email Notification
```bash
./scripts/audit_master.sh nsoni44 reports security-team@example.com
```

### Run Individual Handler
```bash
./handlers/secret_scanning.sh nsoni44
```

### Run Individual Handler and Redirect to File
```bash
./handlers/secret_scanning.sh nsoni44 csv > secret_scanning_report.csv
```

---

## Advanced Usage

### Create Custom Handler

To create a new handler:

1. Copy an existing handler as template
2. Modify to audit your specific concern
3. Ensure CSV output format matches pattern
4. Output statistics JSON to stderr
5. Add to HANDLERS array in `audit_master.sh`

**Handler Template:**
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

log_info "Auditing [FEATURE] for $OWNER"

# Output CSV header
echo "repo,visibility,archived,[METRICS]"

# Fetch repos and audit
# ...

# Output stats to stderr for master script
cat >&2 <<EOF
{
  "handler": "[handler_name]",
  "total": $TOTAL,
  "[metric1]": $VALUE1,
  "[metric2]": $VALUE2
}
EOF
```

---

## Integration Points

### CI/CD Pipeline
Add to GitHub Actions workflow:
```yaml
- name: Run Security Audit
  run: ./scripts/audit_master.sh ${{ github.repository_owner }} reports
```

### Scheduled Audits
Schedule via cron:
```bash
0 2 * * * /path/to/audit_master.sh nsoni44 /reports /path/to/email.txt
```

### Slack Notifications
Extend master script to send to Slack webhook after audit completion.

---

## Troubleshooting

### "gh is not authenticated"
```bash
gh auth login
```

### Permission Denied
Make scripts executable:
```bash
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
```

### Missing jq
Install JSON processor:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

---

## Future Enhancements

Planned features for expansion:

1. **More Handlers**
   - Vulnerability scanning
   - Compliance checking (CIS, SOC2)
   - License scanning
   - Commit signing verification

2. **Better Reporting**
   - HTML report generation
   - Visual charts and graphs
   - Historical trend analysis
   - Compliance scoring

3. **Automation**
   - Automatic remediation
   - Policy enforcement
   - Integration with DevOps tools

4. **Multi-Repository**
   - Cross-organization audits
   - Consolidated dashboards
   - Custom filtering and sorting

---

## License

This project is provided as-is for security auditing purposes.

---

## Support

For issues or questions, refer to the handler scripts or common.sh documentation.
