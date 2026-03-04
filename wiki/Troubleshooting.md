# Troubleshooting

Common issues and their solutions when running GitHub Security Audit.

---

## Installation Issues

### "gh: command not found"

**Problem:** GitHub CLI not installed

**Solution:**
```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt-get install gh

# Or download from:
# https://cli.github.com/
```

### "jq: command not found"

**Problem:** JSON processor not installed

**Solution:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Or download from:
# https://stedolan.github.io/jq/download/
```

---

## Authentication Issues

### "gh is not authenticated"

**Problem:** GitHub CLI not logged in

**Solution:**
```bash
# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status

# If still failing, try re-authenticating
gh auth logout
gh auth login
```

### "Permission denied" accessing repositories

**Problem:** No access to the repository or organization

**Solution:**
1. Verify you have access to the repository:
   ```bash
   gh repo view OWNER/REPO_NAME
   ```

2. Check organization membership:
   ```bash
   gh api /user/memberships/orgs
   ```

3. Ensure you're logged in with correct account:
   ```bash
   gh auth status
   ```

---

## Script Execution Issues

### "Permission denied" on scripts

**Problem:** Scripts not executable

**Solution:**
```bash
# Make all scripts executable
chmod +x scripts/*.sh handlers/*.sh lib/*.sh

# Or make individual script executable
chmod +x scripts/audit_master.sh
```

### "No such file or directory"

**Problem:** Running scripts from wrong directory

**Solution:**
```bash
# Always run from project root
cd /path/to/github-security-audit

# Then run scripts
./scripts/audit_master.sh YOUR_OWNER reports
```

---

## Audit Execution Issues

### No reports generated

**Problem:** Audit ran but no output files

**Solutions:**

1. **Check reports directory exists:**
   ```bash
   mkdir -p reports
   ```

2. **Verify permissions:**
   ```bash
   cd reports && touch test.txt && rm test.txt
   ```

3. **Check disk space:**
   ```bash
   df -h
   ```

4. **Run with debug output:**
   ```bash
   bash -x scripts/audit_master.sh YOUR_OWNER reports
   ```

### Empty or incomplete reports

**Problem:** Reports generated but missing data

**Causes:**
- No repositories found for owner
- All repositories are archived
- API rate limit hit
- Network connectivity issue

**Solution:**
```bash
# Verify repositories exist
gh repo list YOUR_OWNER

# Check API rate limit
gh api rate_limit

# Check network connectivity
gh api /user
```

### Audit fails on specific repository

**Problem:** "Cannot access repo XYZ"

**Causes:**
- Repository doesn't exist
- No access to repository
- Repository is archived
- Network issue

**Solution:**
```bash
# Test specific repository access
gh repo view YOUR_OWNER/REPO_NAME

# If error, check:
# 1. Repository name spelling
# 2. Your access permissions
# 3. Repository exists and isn't deleted
```

---

## API Issues

### Rate limit exceeded

**Problem:** "API rate limit exceeded"

**Details:**
- GitHub API limit: 60 requests/hour (unauthenticated)
- GitHub API limit: 5,000 requests/hour (authenticated)

**Solutions:**

1. **Wait for rate limit reset:**
   ```bash
   # Check when rate limit resets
   gh api rate_limit | jq '.rate.reset' | xargs -I {} date -d @{}
   ```

2. **Ensure you're authenticated** (increases limit to 5,000/hour):
   ```bash
   gh auth status
   ```

3. **Space out audits:**
   ```bash
   # Audit organizations sequentially with delays
   for org in org1 org2 org3; do
     ./scripts/audit_master.sh $org reports/$org
     sleep 60  # Wait between audits
   done
   ```

### API timeouts

**Problem:** "Request timeout" or slow responses

**Solutions:**
1. Check network connection
2. Try again during off-peak hours
3. Reduce number of repositories audited
4. Check GitHub status: https://www.githubstatus.com/

---

## Output Format Issues

### Malformed JSON in statistics

**Problem:** JSON parse errors

**Solution:**
```bash
# Validate JSON output
./scripts/audit_master.sh YOUR_OWNER reports 2>&1 | jq empty

# If specific handler failing, test individually
./handlers/secret_scanning.sh YOUR_OWNER | jq empty
```

### CSV formatting issues

**Problem:** CSV not importing correctly into spreadsheet

**Solution:**
1. Ensure no commas in repository names
2. Check file encoding (should be UTF-8)
3. Try different CSV delimiter if needed

---

## Performance Issues

### Audit taking too long

**Problem:** Audit runs for extended period

**Causes:**
- Large number of repositories
- Network latency
- API rate limiting (throttling)

**Solutions:**

1. **Check how many repos you're auditing:**
   ```bash
   gh repo list YOUR_OWNER --limit 500 | wc -l
   ```

2. **Audit fewer repositories:**
   - Modify `--limit` in `lib/common.sh`
   - Filter by organization instead of user

3. **Run during off-peak hours:**
   - Night time in your timezone
   - Weekends

4. **Use faster network connection**

---

## Handler-Specific Issues

### Secret scanning shows "na"

**Problem:** Secret scanning status unavailable

**Causes:**
- Private repositories on free plan
- Repository is archived
- Feature not enabled for organization

**Solution:**
- Enable GitHub Advanced Security for private repos (requires paid plan)
- Verify organization settings
- Archive status is expected behavior

### Code scanning shows "disabled" despite having workflows

**Problem:** CodeQL configured but showing as disabled

**Solution:**
This is expected if:
- Workflows haven't run yet
- No scan results available yet
- Workflow is disabled

Run CodeQL workflow manually:
```bash
gh workflow run codeql.yml --repo YOUR_OWNER/REPO_NAME
```

### Branch protection shows "false" for default branch

**Problem:** Branch protection not enabled

**Solution:**
This is information, not an error. To enable:
```bash
# Via web UI:
# Settings → Branches → Add rule

# Or use automation script:
./scripts/enable_branch_protection.sh false YOUR_OWNER
```

---

## Common Error Messages

### "fatal: not a git repository"

**Problem:** Running from wrong directory

**Solution:**
```bash
cd /path/to/github-security-audit
./scripts/audit_master.sh YOUR_OWNER reports
```

### "jq: parse error"

**Problem:** Invalid JSON from GitHub API

**Solution:**
1. Check GitHub API status: https://www.githubstatus.com/
2. Re-run audit
3. If persists, file an issue with debug output

### "Error: Could not resolve to a Repository"

**Problem:** Repository name incorrect or doesn't exist

**Solution:**
```bash
# Verify repository exists
gh repo view OWNER/REPO_NAME

# Check repository spelling
gh repo list OWNER | grep REPO_NAME
```

---

## Getting Help

If you're still experiencing issues:

1. **Check the FAQ:** [[FAQ]]
2. **Review documentation:** [[Usage Guide]]
3. **Enable debug mode:**
   ```bash
   bash -x scripts/audit_master.sh YOUR_OWNER reports 2>&1 | tee debug.log
   ```
4. **File an issue on GitHub** with:
   - Your OS and version
   - Output of `gh --version`
   - Output of `jq --version`
   - Debug log (remove sensitive info)

---

**Last Updated:** March 4, 2026
