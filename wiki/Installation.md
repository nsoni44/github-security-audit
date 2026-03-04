# Installation Guide

This guide covers installing GitHub Security Audit and all prerequisites.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

**GitHub CLI (`gh`)**
- Required for interacting with GitHub API
- Must be installed and authenticated

**JSON Processor (`jq`)**
- Required for parsing JSON responses
- Must be available in PATH

**Bash 4.0+**
- Most modern Linux/macOS versions include this
- Windows users can use WSL2 or Git Bash

### System Requirements

- **OS:** macOS 10.15+, Ubuntu 18.04+, or similar Linux
- **Disk:** ~100MB for installation + reports
- **Network:** Outbound HTTPS to GitHub API
- **Permissions:** Read access to GitHub repositories

### GitHub Permissions

**Required Scopes:**
- `repo` - Read repository data
- `read:user` - Read user profile

**Recommended Account:**
- Organization owner or team lead
- Access to all repositories you want to audit

---

## Installation

### Step 1: Get the Code

**Option A: Clone from GitHub**
```bash
git clone https://github.com/YOUR_USERNAME/github-security-audit.git
cd github-security-audit
```

**Option B: Download ZIP**
```bash
# Download from GitHub and extract
unzip github-security-audit-main.zip
cd github-security-audit-main
```

**Option C: Manual Setup**
```bash
mkdir -p github-security-audit/{scripts,handlers,lib,reports}
# Copy files to appropriate directories
```

### Step 2: Install Dependencies

**macOS (using Homebrew):**
```bash
brew install gh jq
```

**Ubuntu/Debian (using apt):**
```bash
sudo apt-get update
sudo apt-get install gh jq
```

**CentOS/RHEL (using yum):**
```bash
sudo yum install gh jq
```

**Alpine (using apk):**
```bash
apk add github-cli jq
```

**Or from source:**
- GitHub CLI: https://cli.github.com
- jq: https://stedolan.github.io/jq/download/

### Step 3: Make Scripts Executable

```bash
cd github-security-audit
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
```

Verify:
```bash
ls -la scripts/audit_master.sh  # Should show -rwxr-xr-x
```

### Step 4: Authenticate with GitHub

```bash
gh auth login
```

Follow the prompts:
1. GitHub.com or GitHub Enterprise? → `GitHub.com`
2. What is your preferred protocol for Git operations? → `HTTPS`
3. Authenticate Git with your GitHub credentials? → `Y`
4. How would you like to authenticate GitHub CLI? → `Login with a web browser`

Alternative (device flow):
```bash
gh auth login --web
```

Verify authentication:
```bash
gh auth status
```

Expected output:
```
  ✓ Logged in to github.com as YOUR_USERNAME
  ✓ Git operations for github.com configured to use https protocol.
  ✓ Token: ghu_****
```

---

## Configuration

### Environment Variables (Optional)

Create `.env` file (optional, not recommended for secrets):

```bash
# .env
GITHUB_OWNER=my-github-username
REPORT_DIR=./reports
EMAIL_TO=security-team@company.com
AUDIT_SCHEDULE="0 2 * * *"  # 2 AM daily
```

Load in shell:
```bash
source .env
./scripts/audit_master.sh $GITHUB_OWNER $REPORT_DIR $EMAIL_TO
```

### Configuration for CI/CD

**GitHub Actions:**

Create `.github/workflows/security-audit.yml`:

```yaml
name: Security Audit
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y gh jq
      
      - name: Run security audit
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          ./scripts/audit_master.sh ${{ github.repository_owner }} ./reports
      
      - name: Upload reports
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: reports/
```

**GitLab CI:**

Create `.gitlab-ci.yml`:

```yaml
security_audit:
  schedule:
    - cron: "0 2 * * *"
  script:
    - apt-get update
    - apt-get install -y gh jq
    - gh auth login --with-token <(echo $GITLAB_TOKEN)
    - ./scripts/audit_master.sh $CI_PROJECT_NAMESPACE ./reports
  artifacts:
    paths:
      - reports/
    expire_in: 30 days
```

---

## Verification

### Check Installation

```bash
# Navigate to project directory
cd github-security-audit

# Verify all components
echo "=== Checking Scripts ===" && ls -la scripts/*.sh
echo "=== Checking Handlers ===" && ls -la handlers/*.sh
echo "=== Checking Library ===" && ls -la lib/*.sh
echo "=== Checking Reports Dir ===" && ls -ld reports/
```

### Test Execution

**Test GitHub CLI:**
```bash
gh auth status
```

**Test jq:**
```bash
gh api user --jq '.login'
```

**Test Scripts:**
```bash
# Check syntax on all scripts
for script in scripts/*.sh handlers/*.sh lib/*.sh; do
  bash -n "$script" && echo "✓ $script" || echo "✗ $script"
done
```

**Run Dry-Run (No Changes):**
```bash
# This will audit but not save reports
./handlers/secret_scanning.sh YOUR_GITHUB_OWNER csv | head -5
```

### First Audit

```bash
# Run audit for your GitHub username
./scripts/audit_master.sh YOUR_GITHUB_USERNAME reports

# Check output
echo "Reports created at $(date +%Y%m%d)"
ls -lh reports/
```

---

## Troubleshooting

### ❌ "gh: command not found"

**Solution:** GitHub CLI not installed

```bash
# macOS
brew install gh

# Linux  
sudo apt-get install gh

# Verify
which gh
```

### ❌ "jq: command not found"

**Solution:** jq not installed

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq

# Verify
which jq
```

### ❌ "gh is not authenticated"

**Solution:** GitHub CLI not logged in

```bash
gh auth login
# Follow prompts and verify
gh auth status
```

### ❌ "Permission denied" on scripts

**Solution:** Scripts not executable

```bash
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
```

### ❌ "Cannot access repository"

**Possible causes:**
- Not authenticated with `gh auth login`
- Token lacks required permissions
- Repository doesn't exist or you don't have access

**Solution:**
```bash
# Check authentication
gh auth status

# Test repo access
gh repo view YOUR_OWNER/REPO_NAME

# If error, try re-authenticating
gh auth logout
gh auth login
```

### ❌ "Rate limit exceeded"

**Cause:** GitHub API rate limit

**Solution:**
- Wait 1 hour (rate limit resets)
- Use Personal Access Token instead of default auth
- Reduce number of repositories

```bash
# Check current limits
gh api rate_limit --jq '.rate_limit'

# Wait for reset
```

### ❌ "No such file or directory"

**Cause:** Running from wrong directory or missing files

**Solution:**
```bash
# Verify you're in project directory
pwd
# Should end with: github-security-audit

# Verify all files exist
ls -la handlers/ scripts/ lib/
```

---

## Advanced Installation

### Docker Installation

Create `Dockerfile`:

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    gh \
    jq \
    git \
    bash

WORKDIR /app
COPY . .

RUN chmod +x scripts/*.sh handlers/*.sh lib/*.sh

ENTRYPOINT ["./scripts/audit_master.sh"]
```

Build and run:
```bash
docker build -t github-security-audit .
docker run -e GH_TOKEN=$TOKEN \
  -v $(pwd)/reports:/app/reports \
  github-security-audit YOUR_OWNER reports
```

### systemd Service (Linux)

Create `/etc/systemd/system/github-audit.service`:

```ini
[Unit]
Description=GitHub Security Audit
After=network.target

[Service]
Type=oneshot
User=audit
WorkingDirectory=/opt/github-security-audit
ExecStart=/opt/github-security-audit/scripts/audit_master.sh YOUR_OWNER /var/log/github-audit
Environment="GH_TOKEN=your_token_here"

[Install]
WantedBy=multi-user.target
```

Enable timer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable github-audit.service
```

### Cron Job (Daily Audit)

```bash
# Edit crontab
crontab -e

# Add line (runs daily at 2 AM)
0 2 * * * cd /path/to/github-security-audit && ./scripts/audit_master.sh YOUR_OWNER /var/log/github-audit >> /var/log/github-audit.log 2>&1
```

---

## Next Steps

After successful installation:

1. **Read [[Quick Start]]** - Run your first audit in 5 minutes
2. **Review [[Usage Guide]]** - Understand all features
3. **Check [[Best Practices]]** - Operational guidelines
4. **Explore [[Handler Development]]** - Create custom handlers (optional)

---

## Support

- **Issues?** See [[Troubleshooting]]
- **Questions?** Check [[FAQ]]
- **Need help?** Create a GitHub Issue

---

**Last Updated:** March 4, 2026
