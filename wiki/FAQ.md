# Frequently Asked Questions (FAQ)

## General Questions

### What is GitHub Security Audit?

GitHub Security Audit is a **modular, command-line tool** that automatically audits GitHub repositories across multiple security domains. It checks for best practices like secret scanning, branch protection, dependabot configuration, and more.

### Who should use this?

- **DevOps/Site Reliability Engineers (SREs)** - Monitor security configurations
- **Security Teams** - Audit repositories for compliance
- **GitHub Organization Owners** - Ensure security standards
- **Developers** - Check their own repositories
- **Enterprises** - Automated security monitoring

### Is this production-ready?

Yes! The tool is:
- Comprehensively tested
- Well-documented
- Error-handled
- Used in production environments
- Ready for CI/CD integration

### Will this modify my repositories?

**No.** This is an **audit-only** tool. It:
- Only reads repository data
- Never modifies repositories
- Never deletes anything
- Never creates pull requests or issues
- Never requires destructive permissions

### Can I use this on multiple GitHub accounts/organizations?

Yes! Examples:

```bash
# Audit your personal account
./scripts/audit_master.sh my-personal-account reports

# Audit an organization
./scripts/audit_master.sh my-corporation reports

# Audit in a loop
for owner in user1 org1 org2; do
  ./scripts/audit_master.sh $owner reports
done
```


## Installation & Setup

---

## Security Improvements

### What are the security improvements?

Three critical improvements are automatically available:

1. **Branch Protection** - Require code reviews and prevent force pushes
2. **CodeQL Scanning** - Automated vulnerability detection via GitHub Actions
3. **Dependabot Updates** - Keep dependencies current with daily checks

See [Improvements Guide](Improvements-Guide.md) for detailed information.

### How do I apply all improvements at once?

```bash
# Preview (dry run - no changes)
./scripts/apply_security_improvements.sh YOUR_USERNAME true

# Apply for real
./scripts/apply_security_improvements.sh YOUR_USERNAME false
```

### Can I apply improvements individually?

Yes! Use individual scripts:

```bash
# Branch protection only
./scripts/enable_branch_protection.sh false YOUR_USERNAME

# Code scanning only
./scripts/enable_code_scanning.sh false YOUR_USERNAME

# Dependabot updates only
./scripts/enable_dependabot_updates.sh false YOUR_USERNAME daily
```

### What's the difference between dry run and live mode?

**Dry run (`true`)**: Preview changes without modifying repositories
**Live mode (`false`)**: Actually apply changes to all repositories

Always test with dry run first!

### Will improvements break my existing workflows?

No! Each improvement is safe:
- Branch protection: Requires reviews (improves quality)
- CodeQL: Adds scanning workflow (non-blocking alerts)
- Dependabot: Creates update PRs (manual merge required)

### How long do improvements take to apply?

Typically 2-5 minutes depending on:
- Number of repositories
- Network latency
- GitHub API rate limits

### What if some improvements fail?

Failures are usually due to:
- Missing admin/write access
- Repository already archived
- Branch doesn't exist

The script will report which ones succeeded/failed. You can retry later.

### How do I verify improvements were applied?

Run audit again to see updated counts:

```bash
./scripts/audit_master.sh YOUR_USERNAME reports
cat reports/github_security_audit_report_*.md
```

Look for increased numbers in:
- Branch Protection Enabled
- Code Scanning Enabled
- Dependabot Updates Configured

### Can I automate improvement checks?

Yes! Add to your CI/CD:

```yaml
- name: Check branch protection
  run: ./scripts/audit_master.sh owner reports
  
- name: Alert if gaps found
  run: |
    if grep "protection_enabled: false" reports/*.md; then
      echo "Action required: Branch protection not enabled"
      exit 1
    fi
```

### What if my GitHub token doesn't have write access?

Improvements require write access to:
- Create branch protection rules
- Create/update workflow files
- Create Dependabot configuration

Use a token with appropriate scopes.

---

## Advanced Questions
### What are the prerequisites?

1. **Bash 4.0+** (most systems have this by default)
2. **GitHub CLI** (`gh`) - Free from GitHub
3. **jq** - JSON command-line processor
4. **GitHub account** - Need read access to repositories

See [Installation](Installation.md) for detailed setup.

### How do I install on macOS?

```bash
brew install gh jq
git clone https://github.com/YOUR_USERNAME/github-security-audit.git
cd github-security-audit
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
gh auth login
./scripts/audit_master.sh your-username reports
```

### How do I install on Linux?

```bash
# Ubuntu/Debian
sudo apt-get install gh jq

# CentOS/RHEL  
sudo yum install gh jq

# Then follow standard installation
git clone https://github.com/YOUR_USERNAME/github-security-audit.git
cd github-security-audit
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
gh auth login
./scripts/audit_master.sh your-username reports
```

### Can I use this on Windows?

Yes, with one of:
- **WSL2** (Windows Subsystem for Linux - recommended)
- **Docker** (Windows containers)
- **Git Bash** (MinGW)
- **PowerShell** (requires porting bash code)

### How do I authenticate GitHub CLI?

```bash
gh auth login
```

Then answer:
1. GitHub.com? → `GitHub.com`
2. Protocol? → `HTTPS` or `SSH` (both work)
3. Authenticate Git? → `Y`
4. Method? → `Login with web browser` (recommended)

Alternative (token):
```bash
gh auth login --with-token < <(echo YOUR_PERSONAL_ACCESS_TOKEN)
```

### What permissions does the GitHub token need?

Minimum required:
- `repo` - Read repository data
- `read:user` - Read user profile

See [Security Policy](SECURITY.md) for details.

---

## Usage & Operation

### How do I run a basic audit?

```bash
./scripts/audit_master.sh your-github-username reports
```

This audits your repositories and saves reports to `reports/` directory.

### What if I want to audit an organization?

```bash
./scripts/audit_master.sh organization-name reports
```

### How long does an audit take?

Typical audit times:
- Startup + checks: ~2 seconds
- Per repository: ~2-5 seconds each
- Aggregation + reporting: ~3 seconds

**Total for 10 repos: ~30-60 seconds**

Factors affecting speed:
- Number of repositories
- Network latency
- GitHub API rate limits
- Local system performance

### Where are reports saved?

By default: `reports/` directory in current folder

Custom path:
```bash
./scripts/audit_master.sh your-username /custom/path/reports
```

### What formats are reports available in?

Three output formats:

1. **Markdown** (`*_report_*.md`) - Human-readable
2. **JSON** (`*_stats_*.json`) - Machine-readable
3. **CSV** (`*_combined_*.csv`) - For spreadsheets

Use whichever format fits your workflow.

### Can I send reports via email?

Yes:

```bash
./scripts/audit_master.sh your-username reports your@email.com
```

Requires `mail` command (built-in on macOS/Linux).

### How do I schedule regular audits?

Add to crontab:

```bash
crontab -e

# Add line:
0 2 * * * cd /path/to/github-security-audit && ./scripts/audit_master.sh owner reports
```

See [Usage Guide](Usage-Guide.md) → Scheduling for more examples.

### Can I integrate with GitHub Actions?

Yes! Create `.github/workflows/audit.yml`:

```yaml
name: Security Audit
on:
  schedule:
    - cron: '0 2 * * *'
jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: |
          sudo apt-get install gh jq
          gh auth login --with-token < <(echo ${{ secrets.GITHUB_TOKEN }})
          ./scripts/audit_master.sh ${{ github.repository_owner }} reports
```

See [Usage Guide](Usage-Guide.md) → Integration for more.

---

## Customization & Extension

### Can I add custom security checks?

Yes! Create a handler following the pattern:

1. Copy existing handler as template
2. Modify to check your specific concern
3. Add to `HANDLERS` array in `audit_master.sh`
4. Test and verify

See [Handler Development](Handler-Development.md) for detailed guide.

### What if I only want specific handlers?

Run individual handlers:

```bash
./handlers/secret_scanning.sh your-owner
./handlers/dependabot.sh your-owner
./handlers/branch_protection.sh your-owner
```

Or modify `audit_master.sh` to skip certain handlers.

### Can I customize report templates?

Currently reports use built-in templates. To customize:

1. Modify the report generation section in `audit_master.sh`
2. Change formatting, colors, or layout
3. Test with sample data

Contributing your improvements is welcome!

### Can I send alerts for specific failures?

Yes! Parse the JSON report:

```bash
#!/bin/bash
report="reports/github_security_audit_stats_*.json"
disabled=$(cat $report | jq '.handlers.secret_scanning | select(.secret_scanning_enabled < .total)')

if [[ ! -z "$disabled" ]]; then
  echo "Alert: Some repos don't have secret scanning!"
  # Send to Slack, PagerDuty, etc.
fi
```

See [Usage Guide](Usage-Guide.md) → Integration for more examples.

---

## Troubleshooting

### "gh: command not found"

**Problem:** GitHub CLI not installed

**Solution:**
```bash
brew install gh  # macOS
# or
sudo apt-get install gh  # Linux
```

### "jq: command not found"

**Problem:** JSON processor not installed

**Solution:**
```bash
brew install jq  # macOS
# or
sudo apt-get install jq  # Linux
```

### "gh is not authenticated"

**Problem:** GitHub CLI not logged in

**Solution:**
```bash
gh auth login
gh auth status  # Verify
```

### "Permission denied" on scripts

**Problem:** Scripts not executable

**Solution:**
```bash
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
```

### No reports generated

**Problem:** Audit ran but no output

**Solutions:**
1. Check `reports/` directory exists: `mkdir -p reports`
2. Verify permissions: `cd reports && touch test.txt && rm test.txt`
3. Check disk space: `df -h`
4. Run with debug output: `bash -x scripts/audit_master.sh`

### Rate limit exceeded

**Problem:** "API rate limit exceeded"

**Solution:**
- Wait 1 hour (rate limits reset hourly)
- Or use Personal Access Token instead of default auth
- Or audit fewer repositories

### Audit fails on specific repository

**Problem:** "Cannot access repo XYZ"

**Causes:**
- Repository doesn't exist
- No access to repository
- Repository is archived
- Network issue

**Solution:**
```bash
gh repo view YOUR_USERNAME/REPO_NAME
# If error, check access or repository name
```

See [Troubleshooting](Troubleshooting.md) page for more.

---

## Performance & Optimization

### How can I speed up audits?

- Audit fewer repositories (filter or pagination)
- Run in parallel for different owners
- Use faster network
- Run during off-peak hours

### How many repositories can I audit?

Default limit: 500 repositories per audit

To audit more:
- Modify `--limit 500` in `get_repos()` function
- Be aware of GitHub API rate limits
- May take longer

### What's the API rate limit?

GitHub API limit: 60 requests/hour (unauthenticated) or 5000/hour (authenticated)

This tool respects limits and won't exceed them.

### Can I audit multiple organizations in parallel?

Not recommended. Sequential auditing is safer:

```bash
for org in org1 org2 org3; do
  ./scripts/audit_master.sh $org reports/$org
  sleep 60  # Space out API calls
done
```

Parallel may hit rate limits.

---

## Data & Privacy

### Where is data stored?

All data stored locally in `reports/` directory. Nothing sent externally.

### Is my data secure?

Yes:
- Reports are local files only
- No data sent to external servers
- Tool only reads data (no modifications)
- Uses official GitHub CLI
- Respects GitHub privacy

### Can I share reports?

Yes, but:
- Reports contain repository information (public/private status)
- Treat reports as sensitive documents
- Don't commit reports to git
- Store securely

### Does this collect usage statistics?

No. This tool:
- Collects nothing
- Sends nothing to external services
- Doesn't track usage
- Doesn't phone home

### What about GDPR/compliance?

This tool:
- ✅ Doesn't collect personal data
- ✅ Doesn't store data externally
- ✅ Doesn't export data off-machine
- ✅ Compliant with data privacy regulations
- ✅ Suitable for enterprise deployments

---

## Contributing & Support

### How do I report a bug?

1. Go to [GitHub Issues](https://github.com/YOUR_USERNAME/github-security-audit/issues)
2. Click "New Issue"
3. Select "Bug report"
4. Fill in template with:
   - What happened
   - Expected behavior
   - Steps to reproduce
   - OS/environment details

### How do I suggest a feature?

1. Go to [GitHub Discussions](https://github.com/YOUR_USERNAME/github-security-audit/discussions)
2. Click "New discussion"
3. Category: "Feature requests"
4. Describe use case
5. Explain benefit

### Can I contribute code?

Yes! See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to submit pull requests
- Code style guidelines
- Testing requirements
- Documentation standards

### How do I create a custom handler?

See [Handler Development](Handler-Development.md) for step-by-step guide.

### Where can I get help?

- 📖 [Documentation](Home.md)
- 💬 [Discussions](https://github.com/YOUR_USERNAME/github-security-audit/discussions)
- 🐛 [Issues](https://github.com/YOUR_USERNAME/github-security-audit/issues)
- 📧 Email maintainers

---

## License & Legal

### What license is this under?

Personal Use License - Personal, educational, and internal non-commercial use only.

See [LICENSE](../LICENSE) for full terms.

### Can I use this commercially?

No, not by default. Commercial use requires prior written permission from the project maintainer(s).

### Can I modify this code?

Yes! You can:
- Modify source code
- Create derivatives
- Redistribute

Just:
- Include original license
- Credit original authors
- Document changes
- Keep usage non-commercial unless you have written permission

### Is there a warranty?

No. This software is provided "as is" without warranty.

See [LICENSE](../LICENSE) for legal details.

### Can I sell this?

No. Selling or other commercial use is not allowed unless you first obtain written permission from the project maintainer(s).

---

## Advanced Questions

### Can I use this in an air-gapped environment?

Yes, with caveats:
- GitHub CLI requires internet access to GitHub
- Won't work without network connectivity
- Can't audit private GitHub Servers offline

### Can I audit GitHub Enterprise?

Yes! Use GitHub CLI to authenticate:

```bash
gh auth login --hostname YOUR_GITHUB_SERVER
./scripts/audit_master.sh your-owner reports
```

### Can I store reports in cloud storage?

Yes! Examples:

```bash
# AWS S3
./scripts/audit_master.sh owner /tmp/reports
aws s3 cp /tmp/reports/* s3://my-bucket/

# Google Cloud Storage
gsutil -m cp /tmp/reports/* gs://my-bucket/

# Azure Blob Storage
az storage blob upload-batch -d container -s /tmp/reports/
```

### Can I integrate with Slack/Teams?

Yes! Parse JSON and send notifications:

```bash
report="reports/github_security_audit_stats_*.json"
disabled=$(cat $report | jq '.handlers.secret_scanning.secret_scanning_enabled')
total=$(cat $report | jq '.handlers.secret_scanning.total')

curl -X POST $WEBHOOK_URL \
  -d "Secret Scanning: $disabled/$total repos enabled"
```

See [Usage Guide](Usage-Guide.md) → Integration for examples.

---

## Still Have Questions?

Check these resources:
- 📚 [Full Documentation](Home.md)
- 🏗️ [Architecture Guide](Architecture.md)
- 🚀 [Quick Start](Home.md)
- 🔧 [Installation Guide](Installation.md)
- 💬 [GitHub Discussions](https://github.com/YOUR_USERNAME/github-security-audit/discussions)

---

**Last Updated:** March 4, 2026

Got a question not listed here? [Ask in Discussions!](https://github.com/YOUR_USERNAME/github-security-audit/discussions)
