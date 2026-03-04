# Security Review

Security considerations and safety guidelines for GitHub Security Audit.

---

## 🔒 Security Overview

GitHub Security Audit is designed with security as a priority:

- ✅ **Read-only operations** - No destructive changes
- ✅ **Local data storage** - All reports stored locally
- ✅ **Official tools** - Uses GitHub CLI (official)
- ✅ **No external services** - No data sent to third parties
- ✅ **Open source** - Transparent, auditable code
- ✅ **Minimal dependencies** - Only gh, jq, bash

---

## What This Tool Does

### ✅ Safe Operations

- **Fetch** repository metadata via GitHub API
- **Read** security settings and configurations
- **Generate** local reports in CSV/JSON/Markdown
- **Display** statistics and summaries

### ❌ What It Does NOT Do

- **Modify** repository settings
- **Delete** or change any data
- **Upload** data to external services
- **Execute** arbitrary code from repositories
- **Store** credentials (uses gh CLI auth)
- **Track** usage or send telemetry

---

## Data Privacy

### What Data Is Collected?

The tool fetches PUBLIC information from GitHub API:

- Repository names and visibility status
- Security feature enablement status
- Branch protection rules
- Dependabot configuration
- Code scanning status
- Repository configuration settings

### Where Is Data Stored?

- **Locally only** - All reports in `reports/` directory
- **No cloud uploads** - Data never leaves your machine
- **User-controlled** - You decide where reports go

### What About Sensitive Data?

- ✅ No credentials stored in reports
- ✅ No repository source code accessed
- ✅ No private repository content read
- ✅ Only configuration metadata collected
- ✅ You control report distribution

---

## Permissions Required

### GitHub CLI Permissions

When you run `gh auth login`, you grant:

- **Read** access to repositories
- **Read** access to organization data
- **Read** access to user profile

The tool **does NOT** require or request:

- Write access to repositories
- Admin permissions
- Webhook management
- Deploy key access

### Verifying Permissions

```bash
# Check what scopes you've granted
gh auth status

# Review token permissions
gh api user | jq .
```

---

## Credential Management

### How Authentication Works

The tool uses GitHub CLI (`gh`) for authentication:

1. User runs: `gh auth login`
2. GitHub CLI handles OAuth flow
3. Token stored securely by gh CLI
4. Tool uses gh CLI for all API calls

**You never need to provide tokens directly to this tool.**

### Best Practices

✅ **DO:**
- Use `gh auth login` for authentication
- Keep gh CLI updated
- Review gh auth status regularly
- Use personal access tokens with minimal scopes
- Rotate tokens periodically

❌ **DON'T:**
- Hardcode tokens in scripts
- Commit tokens to git
- Share authentication tokens
- Use admin tokens for audits
- Store tokens in environment files

---

## Network Security

### Data Transfer

- ✅ All API calls via HTTPS
- ✅ Uses official GitHub API endpoints
- ✅ Respects rate limiting
- ✅ No unencrypted communication
- ✅ No external dependencies

### Firewall Considerations

Required outbound access:

- `api.github.com` (port 443)
- `github.com` (port 443)

No inbound access required.

---

## Report Security

### Handling Reports

Reports contain information about:
- Repository names and visibility
- Security feature status
- Configuration settings

**Treat reports as moderately sensitive.**

### Secure Storage

```bash
# Store in protected directory
mkdir -p ~/security_audits
chmod 700 ~/security_audits
./scripts/audit_master.sh YOUR_OWNER ~/security_audits

# Or encrypt reports
./scripts/audit_master.sh YOUR_OWNER reports
tar czf reports.tar.gz reports/
gpg -c reports.tar.gz
rm -rf reports/ reports.tar.gz
```

### Sharing Reports

Before sharing:

1. **Review** content for sensitive information
2. **Redact** any private repository names if needed
3. **Consider** who needs access
4. **Use** secure channels (encrypted email, secure file share)
5. **Document** who received reports

---

## Compliance Considerations

### GDPR Compliance

This tool:
- ✅ Does not collect personal data
- ✅ Does not transfer data outside user's control
- ✅ Does not store data on external servers
- ✅ Provides full user control over data
- ✅ Complies with data minimization principles

### For Enterprise Use

When deploying in enterprise:

1. **Review** with security team
2. **Test** in isolated environment first
3. **Document** in security policy
4. **Control** who runs audits
5. **Secure** report storage
6. **Monitor** API usage
7. **Audit** the auditor (log all runs)

---

## Dependency Security

### Direct Dependencies

| Dependency | Source | Security |
|------------|--------|----------|
| GitHub CLI (`gh`) | github.com/cli/cli | ✅ Official GitHub tool |
| jq | stedolan.github.io/jq | ✅ Widely trusted, audited |
| bash | GNU | ✅ System default |

**No npm, pip, or other package manager dependencies.**

### Verifying Dependencies

```bash
# Check gh CLI authenticity
gh version

# Check jq version
jq --version

# Verify bash
bash --version
```

### Keeping Dependencies Updated

```bash
# Update gh CLI
brew upgrade gh  # macOS
# or: sudo apt-get upgrade gh  # Linux

# Update jq
brew upgrade jq  # macOS
# or: sudo apt-get upgrade jq  # Linux
```

---

## Security Best Practices

### Running Audits

1. **Use dedicated service account** (not personal account)
2. **Limit scope** of access token
3. **Run from secure system** (not shared workstation)
4. **Log all audit runs** for audit trail
5. **Review changes** to tool before running

### Code Review

Before using:

1. **Review** all scripts in `scripts/` and `handlers/`
2. **Check** for suspicious commands
3. **Verify** no hardcoded credentials
4. **Test** in non-production environment
5. **Monitor** API calls during test run

### Incident Response

If you suspect compromise:

1. **Revoke** GitHub tokens immediately
2. **Review** audit logs
3. **Check** for unauthorized changes
4. **Rotate** credentials
5. **Investigate** how breach occurred

---

## Audit Trail

### Logging Audit Runs

```bash
# Log all audit activity
./scripts/audit_master.sh YOUR_OWNER reports 2>&1 | tee -a audit_log_$(date +%Y%m%d).log

# Include metadata
echo "[$(date)] User: $(whoami), Host: $(hostname), Owner: YOUR_OWNER" >> audit.log
./scripts/audit_master.sh YOUR_OWNER reports
```

### Monitoring

```bash
# Track who runs audits
echo "$(date),$(whoami),$(hostname),$OWNER" >> audit_tracking.csv

# Alert on unexpected audit runs
if [[ "$(whoami)" != "security_bot" ]]; then
  send_alert "Manual audit run by $(whoami)"
fi
```

---

## Hardening Recommendations

### File Permissions

```bash
# Restrict script access
chmod 750 scripts/*.sh handlers/*.sh
chown security_team:security_team -R .

# Protect reports
chmod 700 reports/
```

### Network Isolation

```bash
# Run in isolated environment (optional)
# Use firewall rules to limit outbound access to GitHub only

# Or use dedicated CI runner
# with network policies
```

### Least Privilege

```bash
# Create dedicated audit user with read-only access
# Don't use admin accounts for routine audits
# Review and minimize token scopes
```

---

## Risk Assessment

### Low Risk

- Running read-only audits
- Storing reports locally
- Using official GitHub CLI
- Following best practices

### Medium Risk

- Sharing reports widely
- Using personal admin tokens
- Running on shared systems
- Storing reports long-term

### High Risk

- Modifying tool without review
- Using compromised credentials
- Storing reports insecurely
- Running with elevated privileges unnecessarily

---

## Security Checklist

Before using in production:

- [ ] Code reviewed by security team
- [ ] Tested in isolated environment
- [ ] Dedicated service account created
- [ ] Token scopes minimized
- [ ] Logging enabled
- [ ] Report storage secured
- [ ] Access controls implemented
- [ ] Incident response plan documented
- [ ] Team trained on secure usage
- [ ] Regular security reviews scheduled

---

## Reporting Security Issues

Found a security issue?

1. **Do NOT** open a public issue
2. **Email** security contact (see SECURITY.md)
3. **Include** details: what, where, impact
4. **Wait** for response before disclosure
5. **Follow** responsible disclosure process

---

## Related Documentation

- [[Best Practices]] - Operational best practices
- [[FAQ]] - Frequently asked questions
- [[Troubleshooting]] - Common issues

---

## Summary

**Key Security Points:**

-  ✅ **Read-only tool** - No destructive operations
- ✅ **Local storage** - All data stays on your machine
- ✅ **Official tools** - Uses trusted dependencies
- ✅ **No tracking** - No telemetry or data sent externally
- ✅ **Transparent** - Open source, auditable code
- ✅ **Authenticated** - Uses GitHub CLI auth securely
- ✅ **Minimal deps** - Only gh, jq, bash required

This tool is designed to be safe for enterprise use with proper operational procedures.

---

**Last Updated:** March 4, 2026
