# Security Policy

## Overview

GitHub Security Audit is an **audit-only tool** designed to safely and securely analyze GitHub repository configurations. This document outlines the security properties and policies.

## 🔒 Security Properties

### What This Tool DOES NOT Do

- ✅ Does not modify repositories
- ✅ Does not delete anything  
- ✅ Does not create pull requests or issues
- ✅ Does not access private repository contents beyond metadata
- ✅ Does not store credentials or secrets
- ✅ Does not send data to external servers
- ✅ Does not require dangerous permissions

### What This Tool DOES Do

- ✅ Reads publicly available repository metadata
- ✅ Checks security feature configuration
- ✅ Generates local audit reports
- ✅ Uses official, maintained GitHub CLI
- ✅ Requires explicit user authentication
- ✅ Respects GitHub API rate limits

## 🔐 Authentication & Permissions

### GitHub Authentication

Uses official GitHub CLI (`gh`) with standard OAuth flow:

```bash
gh auth login
# Opens browser for secure authentication
# No credentials typed into terminal
```

### Required Scopes

Minimum required permissions:
- `repo` - Read repository metadata
- `read:user` - Read user profile

**These permissions DO NOT grant:**
- Repository modification rights
- Ability to delete repositories
- Access to private repository content
- Push/merge capabilities
- Admin actions

### Token Security

- Tokens handled by GitHub CLI (secure)
- Tokens stored in system keychain
- No tokens in code or configuration
- Users manage their own authentication

## 🛡️ Code Security

### Source Code Review

- ✅ Code is open source and transparent
- ✅ No hidden or obfuscated code
- ✅ All dependencies declared
- ✅ Minimal external dependencies

### Dependencies

**Direct Dependencies:**
- `gh` (GitHub CLI) - Official GitHub tool, well-maintained
- `jq` (JSON processor) - Open source, widely used
- `bash` - System default interpreter

**No external package managers** (no npm, pip, cargo, etc.) ✅

### Input Validation

All user input validated:
- Repository names validated
- GitHub usernames validated
- File paths restricted to safe locations
- No arbitrary code execution possible

### Error Handling

- Comprehensive error checking
- Safe failure modes
- No sensitive data in error messages
- Proper exit codes

## 📊 Data Security

### Data Storage

- All data stored locally in `reports/` directory
- Nothing sent to external servers
- Reports stored in unencrypted plaintext (user's responsibility to secure)
- No telemetry or analytics

### Data Privacy

- Users can choose what repositories to audit
- No automatic data collection
- Reports contain only audited repository information
- No personal data beyond GitHub metadata

### Data Retention

- User controls data retention
- Can delete reports anytime
- No external backup or archival

## 🔄 API Security

### GitHub API Usage

- Uses official GitHub API via `gh` CLI
- All communications via HTTPS
- Respects rate limits
- No API key abuse

### Rate Limiting

- GitHub limits: 5000 requests/hour (authenticated)
- Tool respects these limits
- Fails gracefully if exceeded
- Clear error messages

## 🌐 Network Security

### Communication

- All communication via HTTPS
- No unencrypted connections
- Uses GitHub's trusted infrastructure
- No intermediate proxies or logging

### Connectivity

- Requires outbound HTTPS to GitHub
- No callback or "phone home" functionality
- No data exfiltration
- Works with proxies (inherits system proxy settings)

## 🔍 Audit Logging

### What's Logged

- Tool execution and timing
- Handler status and results
- Error conditions and recovery
- API rate limit warnings

### What's NOT Logged

- User credentials (not possible with `gh`)
- Repository contents
- User data
- Authentication tokens

## ♻️ Compliance

### Standards

- ✅ No external data transmission
- ✅ No credential storage
- ✅ No telemetry collection
- ✅ Compliant with GDPR (no PII collected)
- ✅ Suitable for enterprise deployment

### Appropriate For

- ✅ Enterprise organizations
- ✅ Regulated industries
- ✅ Government agencies
- ✅ Healthcare (HIPAA aligned)
- ✅ Financial services (PCI aligned)

## 🚨 Reporting Security Issues

### Vulnerability Disclosure

If you discover a security vulnerability, **please do not create a public issue**.

Instead:

1. **Email security details to:** security@example.com
2. **Include:**
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Your name/affiliation (optional)

3. **We will:**
   - Acknowledge receipt within 24 hours
   - Investigate the issue
   - Develop a fix
   - Coordinate responsible disclosure
   - Credit you (if desired)

### Security Update Process

1. **Issue discovered** → Security team notified
2. **Triage** → Assess impact and severity
3. **Fix development** → Create patch
4. **Testing** → Verify fix works
5. **Release** → Publish security update
6. **Announcement** → Notify users

## 📜 Security Considerations for Users

### Best Practices

1. **Keep tools updated**
   ```bash
   brew upgrade gh jq  # macOS
   sudo apt update && sudo apt upgrade gh jq  # Linux
   ```

2. **Secure your reports**
   - Don't commit to public repositories
   - Store securely if containing private repo info
   - Treat as sensitive documents

3. **Use strong authentication**
   - Enable two-factor authentication (2FA) on GitHub account
   - Use unique, strong passwords
   - Never share tokens or credentials

4. **Audit permissions**
   - Review GitHub CLI permissions: `gh auth status`
   - Revoke old tokens: https://github.com/settings/tokens
   - Use the minimum required permissions

5. **Monitor your account**
   - Review GitHub account activity
   - Check connected applications
   - Remove unused integrations

### When Running in CI/CD

- Use GitHub Actions secrets for credentials
- Never log or output tokens
- Scope tokens minimally
- Rotate regularly
- Store reports securely

### When Running on Shared Systems

- Authenticate as your user (not shared account)
- Keep GitHub token local (in keychain)
- Clean up reports before leaving system
- Don't store credentials in files

## 🔄 Dependency Security

### Dependency Monitoring

- Monitor `gh` and `jq` for security updates
- Subscribe to security advisories
- Test updates before deploying
- Keep audit trail of versions

### Supply Chain Security

- Uses officially released tools only
- Verifies package signatures (GitHub CLI)
- No third-party modifications
- Transparent dependency list

## 📋 Security Checklist

**Before Using:**
- [ ] GitHub account secured with 2FA
- [ ] `gh` and `jq` installed from official sources
- [ ] Authentication working (`gh auth status`)
- [ ] You have repository read access

**When Running:**
- [ ] Running on trusted system
- [ ] No other users accessing reports
- [ ] Network connectivity verified
- [ ] GitHub API accessible

**After Running:**
- [ ] Reports reviewed for accuracy
- [ ] Reports stored securely if sensitive
- [ ] Reports deleted if no longer needed
- [ ] Any issues reported to maintainers

## 🎓 Educational Resources

- [GitHub Security Academy](https://github.com/skills/security)
- [OWASP Security Topics](https://owasp.org/)
- [GitHub API Security](https://docs.github.com/en/rest/about-the-rest-api)

## 📞 Security Questions

For security questions or concerns:

1. **Email:** security@example.com
2. **GitHub Issues:** [Create private security issue](https://github.com/YOUR_USERNAME/github-security-audit/security/advisories)
3. **Discussions:** [Start discussion](https://github.com/YOUR_USERNAME/github-security-audit/discussions)

## 📜 Warranty & Liability

This software is provided **"AS IS"** without warranty. While we've designed it with security in mind, we cannot guarantee it is error-free or suitable for all purposes.

- ✅ We take security seriously
- ✅ We respond promptly to issues
- ✅ We maintain best practices

- ❌ We cannot guarantee perfection
- ❌ We're not liable for misuse
- ❌ We're not liable for third-party tools

See [LICENSE](LICENSE) for full legal terms.

---

**Last Updated:** March 4, 2026

**Security Policy Version:** 1.0

Have security concerns? [Email us](mailto:security@example.com) or [create an issue](https://github.com/YOUR_USERNAME/github-security-audit/security/advisories).
