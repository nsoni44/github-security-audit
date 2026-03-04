# Usage Guide

Complete guide to using GitHub Security Audit in various scenarios.

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Advanced Usage](#advanced-usage)
3. [Individual Handlers](#individual-handlers)
4. [Output Formats](#output-formats)
5. [Scheduling](#scheduling)
6. [Integration](#integration)

---

## Basic Usage

### Simple Audit (Default)

Audit your own GitHub account and save reports to `reports/` directory:

```bash
./scripts/audit_master.sh
```

**Output:**
- Markdown report: `reports/github_security_audit_report_YOUR_LOGIN_*.md`
- JSON stats: `reports/github_security_audit_stats_YOUR_LOGIN_*.json`

### Audit Specific Owner

Audit a specific GitHub user or organization:

```bash
./scripts/audit_master.sh my-github-username
```

Or with custom report directory:

```bash
./scripts/audit_master.sh my-github-username /tmp/audit-reports
```

### Audit with Email Notification

Send report via email after completion:

```bash
./scripts/audit_master.sh my-github-username reports security-team@company.com
```

---

## Advanced Usage

### Suppress Output

Redirect output to file:

```bash
./scripts/audit_master.sh my-org reports > audit.log 2>&1
```

### Run with Custom Paths

```bash
# Use absolute paths
/usr/local/bin/audit_master.sh my-owner /opt/reports
```

### Set Environment Variables

```bash
export OWNER="my-github-org"
export REPORT_DIR="/data/github-audits"

./scripts/audit_master.sh $OWNER $REPORT_DIR
```

### Capture Output for Further Processing

```bash
# Save output for analysis
./scripts/audit_master.sh my-owner reports 2>&1 | tee audit-run-$(date +%s).log

# Parse JSON stats for custom reporting
cat reports/github_security_audit_stats_*.json | jq '.handlers | keys[]'
```

### Dry-Run (Test without Saving)

```bash
# Test handlers without affecting reports
./handlers/secret_scanning.sh my-owner csv | head -20
```


## Individual Handlers

---

## Security Improvements

After running an audit, you can automatically apply proven security best practices to all your repositories.

### Apply All Improvements (Recommended)

```bash
# Preview all improvements (dry run first!)
./scripts/apply_security_improvements.sh YOUR_USERNAME true

# Apply improvements to all repositories
./scripts/apply_security_improvements.sh YOUR_USERNAME false
```

This automates three critical security improvements:

1. **Branch Protection** - Require code reviews before merging
2. **CodeQL Scanning** - Automated vulnerability detection
3. **Dependabot Updates** - Keep dependencies current

### Individual Improvement Scripts

You can run individual improvement scripts manually:

**Enable Branch Protection:**
```bash
./scripts/enable_branch_protection.sh true YOUR_USERNAME
./scripts/enable_branch_protection.sh false YOUR_USERNAME
```

**Enable CodeQL Scanning:**
```bash
./scripts/enable_code_scanning.sh true YOUR_USERNAME
./scripts/enable_code_scanning.sh false YOUR_USERNAME
```

**Enable Dependabot Version Updates:**
```bash
./scripts/enable_dependabot_updates.sh true YOUR_USERNAME daily
./scripts/enable_dependabot_updates.sh false YOUR_USERNAME daily
```

### Verification After Improvements

Run the audit again to verify improvements were applied:

```bash
./scripts/audit_master.sh YOUR_USERNAME reports
cat reports/github_security_audit_report_*.md
```

You should see improvements in:
- Branch protection enabled count
- Code scanning enabled count
- Dependabot updates configured count

See [Improvements Guide](Improvements-Guide.md) for detailed information on each improvement.

---

## Individual Handlers
Each handler can be run independently for specific audits.

### Secret Scanning Handler

Audit secret scanning and push protection:

```bash
./handlers/secret_scanning.sh my-owner
```

**Output Format:**
```csv
repo,visibility,archived,secret_scanning,push_protection
org/repo1,PUBLIC,false,enabled,enabled
org/repo2,PRIVATE,false,na,na
```

**Statistics Output (stderr):**
```json
{
  "handler": "secret_scanning",
  "total": 10,
  "secret_scanning_enabled": 9,
  "push_protection_enabled": 8
}
```

### Dependabot Handler

Audit Dependabot configuration:

```bash
./handlers/dependabot.sh my-owner
```

**Metrics:**
- Dependabot security updates status
- Version updates configuration

### Branch Protection Handler

Audit branch protection rules:

```bash
./handlers/branch_protection.sh my-owner
```

**Metrics:**
- Protection rules enabled
- Required reviews
- Required status checks

### Code Scanning Handler

Audit code scanning (GitHub Advanced Security):

```bash
./handlers/code_scanning.sh my-owner
```

**Metrics:**
- Code scanning enabled
- CodeQL configured
- Active alerts

### Repo Config Handler

Audit repository configurations:

```bash
./handlers/repo_config.sh my-owner
```

**Metrics:**
- Has description
- Has homepage
- Wiki enabled
- Pages enabled
- Forking allowed
- Downloads allowed

---

## Output Formats

### CSV Output

Get structured data for analysis:

```bash
./handlers/secret_scanning.sh my-owner csv
```

**Redirect to file:**
```bash
./handlers/secret_scanning.sh my-owner csv > /tmp/security_report.csv
```

**Import to spreadsheet:**
```bash
# Create Excel/Google Sheets compatible file
./handlers/dependabot.sh my-owner csv > dependabot_report.csv
# Then open in Excel or Google Sheets
```

### JSON Output

Get machine-readable statistics:

```bash
cat reports/github_security_audit_stats_*.json | jq .
```

**Pretty print:**
```bash
cat reports/github_security_audit_stats_*.json | jq '.' | less
```

**Extract specific handler stats:**
```bash
cat reports/github_security_audit_stats_*.json | jq '.handlers.secret_scanning'
```

**Programmatic access:**
```bash
#!/bin/bash
stats=$(cat reports/github_security_audit_stats_*.json)
total=$(echo "$stats" | jq '.metadata.total_repositories')
echo "Total repositories: $total"
```

### Markdown Output

Human-readable report with tables:

```bash
cat reports/github_security_audit_report_*.md
```

**Convert to HTML:**
```bash
# Using pandoc
pandoc -f markdown -t html reports/github_security_audit_report_*.md > report.html

# Using GitHub Flavored Markdown
gh api repos/{OWNER}/{REPO}/markdown \
  --input reports/github_security_audit_report_*.md | \
  tee report.html
```

---

## Scheduling

### Daily Audit (Cron)

Edit crontab:
```bash
crontab -e
```

Add entry:
```bash
# Run daily at 2 AM
0 2 * * * cd /home/user/github-security-audit && ./scripts/audit_master.sh my-org /data/reports >> /var/log/github-audit.log 2>&1

# Run daily at 2 AM with email
0 2 * * * cd /home/user/github-security-audit && ./scripts/audit_master.sh my-org /data/reports admin@company.com

# Run weekly (Sunday at 3 AM)
0 3 * * 0 cd /home/user/github-security-audit && ./scripts/audit_master.sh my-org /data/reports

# Run monthly (1st of month at 4 AM)
0 4 1 * * cd /home/user/github-security-audit && ./scripts/audit_master.sh my-org /data/reports
```

### Multiple Owners (Cron)

```bash
#!/bin/bash
# audit-all.sh - Audit multiple GitHub owners

BASE_DIR="/opt/github-security-audit"
OWNERS=("my-org-1" "my-org-2" "my-user")
REPORT_BASE="/data/github-audits"

for owner in "${OWNERS[@]}"; do
  echo "Auditing $owner..."
  $BASE_DIR/scripts/audit_master.sh "$owner" "$REPORT_BASE/$owner"
  sleep 30  # Space out API calls
done

echo "All audits complete!"
```

Add to crontab:
```bash
0 2 * * * /home/user/audit-all.sh >> /var/log/audit-all.log 2>&1
```

---

## Integration

### GitHub Actions Workflow

Create `.github/workflows/security-audit.yml`:

```yaml
name: GitHub Security Audit
on:
  schedule:
    - cron: '0 2 * * *'  # Daily 2 AM UTC
  workflow_dispatch:     # Manual trigger

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup
        run: |
          sudo apt-get update
          sudo apt-get install -y gh jq
1. [Basic Usage](#basic-usage)
2. [Advanced Usage](#advanced-usage)
3. [Security Improvements](#security-improvements)
4. [Individual Handlers](#individual-handlers)
5. [Output Formats](#output-formats)
6. [Scheduling](#scheduling)
7. [Integration](#integration)
      - name: Run Security Audit
        run: |
          ./scripts/audit_master.sh ${{ github.repository_owner }} ./reports
      
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: security-audit-reports
          path: reports/
          retention-days: 30
      
      - name: Post to Wiki
        run: |
          # Optional: Copy reports to wiki
          cp reports/github_security_audit_report_*.md docs/audit-$(date +%Y-%m-%d).md
```

### Send to Slack

Create webhook integration:

```bash
#!/bin/bash
# Send audit results to Slack

WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
REPORT="reports/github_security_audit_stats_*.json"

# Extract summary from report
TOTAL=$(cat $REPORT | jq '.metadata.total_repositories')
SS_ENABLED=$(cat $REPORT | jq '.handlers.secret_scanning.secret_scanning_enabled')
BP_ENABLED=$(cat $REPORT | jq '.handlers.branch_protection.protection_enabled')

# Send to Slack
curl -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"GitHub Security Audit Report\",
    \"blocks\": [
      {\"type\": \"section\", \"text\": {\"type\": \"mrkdwn\", \"text\": \"*GitHub Security Audit Report*\"}},
      {\"type\": \"section\", \"text\": {\"type\": \"mrkdwn\", \"text\": \"Total Repos: $TOTAL\nSecret Scanning: $SS_ENABLED\nBranch Protection: $BP_ENABLED\"}}
    ]
  }" \
  $WEBHOOK_URL
```

### Email Reports

Send reports automatically (requires mail command):

```bash
./scripts/audit_master.sh my-owner reports security-team@company.com
```

Or with attachment:

```bash
cat reports/github_security_audit_report_*.md | \
  mail -s "GitHub Security Audit $(date +%Y-%m-%d)" \
  -a "reports/github_security_audit_stats_*.json" \
  security-team@company.com
```

### Parse and Alert

Alert on specific failures:

```bash
#!/bin/bash
# Alert if secret scanning disabled

REPORT="reports/github_security_audit_stats_*.json"
ENABLED=$(cat $REPORT | jq '.handlers.secret_scanning.secret_scanning_enabled')
TOTAL=$(cat $REPORT | jq '.handlers.secret_scanning.total')

if [[ $ENABLED -lt $TOTAL ]]; then
  echo "⚠️ WARNING: Not all repos have secret scanning enabled"
  echo "Enabled: $ENABLED / $TOTAL"
  
  # Trigger alert
  curl -X POST https://your-alert-endpoint.com/alert \
    -d "message=Secret%20scanning%20not%20enabled%20on%20all%20repos"
fi
```

### Store Reports in S3

```bash
#!/bin/bash
# Archive reports to AWS S3

BUCKET="my-audit-reports"
REGION="us-east-1"

./scripts/audit_master.sh my-owner /tmp/reports

# Upload to S3
aws s3 cp /tmp/reports/ s3://$BUCKET/$(date +%Y-%m-%d)/ \
  --region $REGION --recursive
```

### Build Compliance Dashboard

```bash
#!/bin/bash
# Generate compliance dashboard from reports

REPORT="reports/github_security_audit_stats_*.json"

echo "# GitHub Security Compliance Dashboard"
echo ""
echo "**Generated:** $(date)"
echo ""
echo "## Summary"
echo ""

# Extract and display key metrics
jq -r '.handlers | to_entries[] | "\(.key): \(.value.total) repos audited"' $REPORT

echo ""
echo "## Compliance Score"

TOTAL_CHECKS=0
ENABLED_CHECKS=0

# Example: Count all enabled features
for handler in secret_scanning dependabot branch_protection code_scanning; do
  ENABLED=$(jq ".handlers.$handler | [.[] | select(type != \"string\" and . == true)] | length" $REPORT 2>/dev/null || echo 0)
  TOTAL=$(jq ".handlers.$handler.total" $REPORT 2>/dev/null || echo 0)
  
  TOTAL_CHECKS=$((TOTAL_CHECKS + TOTAL))
  ENABLED_CHECKS=$((ENABLED_CHECKS + ENABLED))
done

SCORE=$((ENABLED_CHECKS * 100 / TOTAL_CHECKS))
echo "Overall Compliance: $SCORE%"
```

---

## Common Workflows

### Audit Organization and Create Issue

```bash
#!/bin/bash
# Audit organization and create issues for non-compliant repos

ORG="my-organization"
./scripts/audit_master.sh $ORG ./reports

# Parse report and find non-compliant repos
REPORT="reports/github_security_audit_report_${ORG}_*.md"

# Extract repos without secret scanning
grep "false" $REPORT | grep -v "enabled" | while read line; do
  repo=$(echo $line | cut -d'|' -f2 | xargs)
  
  # Create issue (if no existing)
  gh issue create \
    --repo "$ORG/$repo" \
    --title "Enable Secret Scanning" \
    --body "Security audit: Please enable secret scanning on this repository." \
    --label "security" || true
done
```

### Continuous Monitoring

```bash
#!/bin/bash
# Continuous audit with drift detection

PREV_REPORT="previous_stats.json"
CURR_REPORT="current_stats.json"

# Run audit and save current report
./scripts/audit_master.sh my-org ./reports
cp reports/github_security_audit_stats_*.json "$CURR_REPORT"

# Compare with previous report
if [[ -f "$PREV_REPORT" ]]; then
  DIFF=$(diff <(jq -S . "$PREV_REPORT") <(jq -S . "$CURR_REPORT"))
  if [[ ! -z "$DIFF" ]]; then
    echo "⚠️ Security configuration drift detected!"
    echo "$DIFF"
  fi
fi

# Save current as previous for next run
cp "$CURR_REPORT" "$PREV_REPORT"
```

---

## Troubleshooting

See [Troubleshooting](Troubleshooting.md) for common issues.

---

**Last Updated:** March 4, 2026
