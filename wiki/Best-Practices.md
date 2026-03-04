# Best Practices

Operational best practices for using GitHub Security Audit effectively.

---

## Audit Frequency

### Daily Audits (Recommended)

For active development teams:

```bash
# Cron job: Daily at 2 AM
0 2 * * * cd /path/to/github-security-audit && ./scripts/audit_master.sh YOUR_OWNER reports
```

**Benefits:**
- Early detection of security drift
- Track changes over time
- Quick response to issues

### Weekly Audits

For smaller teams or personal projects:

```bash
# Cron job: Every Sunday at 2 AM
0 2 * * 0 cd /path/to/github-security-audit && ./scripts/audit_master.sh YOUR_OWNER reports
```

### On-Demand Audits

For compliance or security reviews:

```bash
# Before major releases
# After security incidents
# During compliance audits
./scripts/audit_master.sh YOUR_OWNER reports
```

---

## Report Management

### Organize by Date

```bash
# Create date-stamped directories
DATE=$(date +%Y-%m-%d)
./scripts/audit_master.sh YOUR_OWNER "reports/$DATE"
```

### Archive Old Reports

```bash
# Keep last 30 days, archive older
find reports/ -name "*.md" -mtime +30 -exec mv {} archive/ \;

# Or compress
find reports/ -name "*.md" -mtime +30 -exec gzip {} \;
```

### Version Control (Carefully)

```bash
# If tracking trends in git
echo "reports/" >> .gitignore  # Don't commit by default

# Only commit anonymized summaries
git add reports/summary_*.json
git commit -m "Security audit summary $(date +%Y-%m-%d)"
```

⚠️ **Warning:** Reports may contain sensitive repository information. Review before committing.

---

## Performance Optimization

### Audit Fewer Repositories

For large organizations:

```bash
# Modify lib/common.sh get_repos() function
gh repo list "$owner" --limit 100  # Instead of 500
```

### Parallel Organization Audits

```bash
# Audit multiple organizations (not in parallel to avoid rate limits)
for org in org1 org2 org3; do
  ./scripts/audit_master.sh "$org" "reports/$org"
  sleep 60  # Wait between audits
done
```

### Filter by Criteria

Modify handlers to skip certain repositories:

```bash
# Skip archived (already done by default)
if [[ "$ARCHIVED" == "true" ]]; then
  continue
fi

# Skip forks
if [[ "$IS_FORK" == "true" ]]; then
  continue
fi

# Skip private repos (if needed)
if [[ "$VISIBILITY" == "PRIVATE" ]]; then
  continue
fi
```

---

## API Rate Limit Management

### Check Rate Limit

```bash
# Before running audit
gh api rate_limit

# Get remaining requests
gh api rate_limit | jq '.rate.remaining'

# Get reset time
gh api rate_limit | jq '.rate.reset' | xargs -I {} date -d @{}
```

### Space Out Audits

```bash
# Audit organizations sequentially with delays
for org in org1 org2 org3; do
  echo "Auditing $org..."
  ./scripts/audit_master.sh "$org" "reports/$org"
  
  echo "Waiting 60 seconds..."
  sleep 60
done
```

### Use Authentication

Always authenticate to get 5,000 requests/hour (vs 60 unauthenticated):

```bash
gh auth login
gh auth status
```

---

## Monitoring & Alerting

### Email Notifications

```bash
# Add to cron job
0 2 * * * cd /path/to/github-security-audit && \
  ./scripts/audit_master.sh YOUR_OWNER reports && \
  echo "Audit complete. See attached reports." | \
  mail -s "GitHub Security Audit $(date +%Y-%m-%d)" \
       -A reports/latest_report.md \
       your@email.com
```

### Slack Notifications

```bash
# Add to audit_master.sh
send_slack_notification() {
  local webhook_url="YOUR_WEBHOOK_URL"
  local message="$1"
  
  curl -X POST "$webhook_url" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \"$message\"}"
}

# At end of audit
send_slack_notification "GitHub audit completed for $OWNER at $(date)"
```

### Trend Monitoring

```bash
# Compare with previous audit
diff reports/previous_stats.json reports/latest_stats.json

# Alert on decreases
PREV_PROTECTED=$(jq '.handlers.branch_protection.protection_enabled' reports/previous_stats.json)
CURR_PROTECTED=$(jq '.handlers.branch_protection.protection_enabled' reports/latest_stats.json)

if [[ $CURR_PROTECTED -lt $PREV_PROTECTED ]]; then
  echo "WARNING: Branch protection decreased from $PREV_PROTECTED to $CURR_PROTECTED"
fi
```

---

## Security Recommendations

### Handle Reports Securely

**DO:**
- ✅ Store reports in secure locations
- ✅ Limit access to security team
- ✅ Encrypt reports if needed
- ✅ Review before sharing
- ✅ Delete old reports regularly

**DON'T:**
- ❌ Commit reports to git
- ❌ Share via unsecured channels
- ❌ Leave reports in public directories
- ❌ Email unencrypted reports
- ❌ Store indefinitely

### Credential Management

```bash
# Use environment variables
export GITHUB_TOKEN="your_token"

# Or use gh CLI (recommended)
gh auth login

# Never hardcode tokens
# BAD: gh auth setup-token ghp_xxxxx
# GOOD: gh auth login (interactive)
```

### Audit Logs

Keep audit logs for compliance:

```bash
# Log all audit runs
./scripts/audit_master.sh YOUR_OWNER reports 2>&1 | tee -a audit.log

# Include timestamp
echo "[$(date)] Running audit for $OWNER" >> audit.log
./scripts/audit_master.sh YOUR_OWNER reports
```

---

## Compliance Integration

### SOC 2 / ISO 27001

Use audits as evidence:

```bash
# Monthly compliance audit
# Store in compliance/evidence/ directory
mkdir -p compliance/evidence
./scripts/audit_master.sh YOUR_OWNER "compliance/evidence/$(date +%Y-%m)"

# Generate summary for auditors
jq . "compliance/evidence/$(date +%Y-%m)/github_security_audit_stats_*.json" > compliance/monthly_summary.json
```

### Continuous Compliance

```bash
# Automated compliance checks
REQUIRED_BRANCH_PROTECTION=10

CURRENT=$(jq '.handlers.branch_protection.protection_enabled' reports/latest_stats.json)

if [[ $CURRENT -lt $REQUIRED_BRANCH_PROTECTION ]]; then
  echo "COMPLIANCE FAILURE: Only $CURRENT/$REQUIRED_BRANCH_PROTECTION repos have branch protection"
  exit 1
fi
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Security Audit

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:      # Manual trigger

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y jq
          
      - name: Install GitHub CLI
        run: |
          curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
          sudo apt-get update
          sudo apt-get install -y gh
          
      - name: Run audit
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          ./scripts/audit_master.sh ${{ github.repository_owner }} reports
          
      - name: Upload reports
        uses: actions/upload-artifact@v3
        with:
          name: security-audit-reports
          path: reports/
```

### GitLab CI

```yaml
security_audit:
  stage: test
  image: ubuntu:latest
  before_script:
    - apt-get update
    - apt-get install -y jq curl
    - curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    - apt-get install -y gh
  script:
    - gh auth login --with-token < $GH_TOKEN_FILE
    - ./scripts/audit_master.sh YOUR_OWNER reports
  artifacts:
    paths:
      - reports/
    expire_in: 30 days
  only:
    - schedules
```

---

## Team Collaboration

### Shared Audit Access

```bash
# Share reports via shared drive
cp reports/latest_* /mnt/shared/security-audits/

# Or use S3
aws s3 sync reports/ s3://company-security-audits/github/
```

### Review Process

1. **Security team runs audit**
2. **Review findings with dev leads**
3. **Create action items for issues**
4. **Track remediation**
5. **Re-audit to verify fixes**

### Automation Scripts

Enable security improvements automatically:

```bash
# Enable all security features for new repositories
./scripts/apply_security_improvements.sh YOUR_OWNER

# Or selectively
./scripts/enable_branch_protection.sh false YOUR_OWNER
./scripts/enable_code_scanning.sh YOUR_OWNER
./scripts/enable_dependabot_updates.sh YOUR_OWNER
```

---

## Documentation

### Maintain Runbook

```markdown
# Security Audit Runbook

## Schedule
- Daily: 2 AM automatic audit
- Monthly: Manual review with team

## Process
1. Check automated audit results
2. Review any failures
3. Create tickets for issues
4. Track remediation progress
5. Re-audit after fixes

## Contacts
- Security Team: security@company.com
- DevOps: devops@company.com
```

### Track Metrics Over Time

```bash
# Extract key metrics to tracking file
echo "$(date +%Y-%m-%d),$(jq '.handlers.branch_protection.protection_enabled' reports/latest_stats.json)" >> metrics/branch_protection.csv

# Plot trends (example with gnuplot)
gnuplot <<EOF
set datafile separator ','
set xdata time
set timefmt "%Y-%m-%d"
set format x "%Y-%m"
plot 'metrics/branch_protection.csv' using 1:2 with lines title 'Branch Protection'
EOF
```

---

## Troubleshooting

See [[Troubleshooting]] for common issues and solutions.

---

##Summary

**Key Takeaways:**

1. **Audit regularly** - Daily for active teams, weekly for smaller projects
2. **Manage reports** - Organize by date, archive old reports, handle securely
3. **Respect rate limits** - Authenticate, space out audits, monitor usage
4. **Automate** - Use cron jobs, CI/CD pipelines, notifications
5. **Monitor trends** - Track metrics over time, alert on regressions
6. **Enable improvements** - Use automation scripts to fix issues
7. **Document** - Maintain runbooks, track progress, share knowledge

---

**Last Updated:** March 4, 2026
