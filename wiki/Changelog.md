# Changelog

Version history and release notes for GitHub Security Audit.

---

## [2.1.0] - 2026-03-04

### 🚀 Added
- **Security improvement automation scripts**
  - `apply_security_improvements.sh` - Master orchestrator for all improvements
  - `enable_branch_protection.sh` - Automated branch protection with PR reviews
  - `enable_code_scanning.sh` - CodeQL workflow creation
  - `enable_dependabot_updates.sh` - Dependabot version updates configuration
- **Protected branch PR fallback mechanism**
  - Automatically creates PRs when direct commits blocked
  - Admin merge attempted after PR creation
  - Graceful handling of branch protection conflicts
- **Comprehensive wiki documentation**
  - Home, Installation, Usage Guide
  - Improvements Guide with automation examples
  - FAQ with 70+ questions answered
  - Security and Publishing guidelines
  - Troubleshooting guide
  - Handler Development guide
  - API Reference
  - Best Practices
  - Security Review

### 🐛 Fixed
- Fixed variable shadowing bug in `branch_protection.sh` handler
  - Renamed `BP_ENABLED` counter to `BP_ENABLED_COUNT`
  - Prevents "unbound variable" error
- Fixed code scanning metric calculation
  - Added `EFFECTIVE_CODE_SCAN` logic
  - Properly accounts for CodeQL workflows
  - More accurate reporting of actual security posture
- Fixed improvement script execution order
  - CodeQL and Dependabot applied before branch protection
  - Prevents 409 conflicts from protected branch direct commits

### 🔧 Changed
- Updated `enable_branch_protection.sh` to support `REQUIRE_REVIEWS=0` mode
  - Allows temporary relaxation of review requirements
  - Facilitates automated configuration updates
- Improved error handling across all handlers
- Enhanced logging with color-coded output
- Better API error messages

### 📚 Documentation
- Added 13+ markdown documentation files
- Created 6 wiki pages (now 12 total)
- Expanded README with badges and examples
- Added QUICKSTART.md for 5-minute setup
- Created ARCHITECTURE.md with system diagrams
- Added CONTRIBUTING.md with guidelines
- Created SECURITY.md with security policy

---

## [2.0.0] - 2026-03-03

### 🎉 Major Release - Modular Architecture

Complete rewrite from monolithic to modular system.

### 🚀 Added
- **Modular handler architecture**
  - `secret_scanning.sh` - Secret scanning & push protection
  - `dependabot.sh` - Dependency management audits
  - `branch_protection.sh` - Branch safety rules
  - `code_scanning.sh` - GHAS & CodeQL checks
  - `repo_config.sh` - Repository settings audit
- **Master orchestrator**
  - `audit_master.sh` - Runs all handlers sequentially
  - Aggregates results from all handlers
  - Generates combined reports
- **Multiple output formats**
  - Markdown reports (human-readable)
  - JSON statistics (machine-readable)
  - Combined CSV (data export)
- **Common utility library**
  - `lib/common.sh` - Shared functions
  - Logging utilities (info, success, error, warn)
  - Prerequisite checks
  - Repository fetching helpers
- **160+ metrics tracked**
  - 2 metrics per handler × 10 repos minimum
  - Comprehensive security coverage
  - Detailed per-repository data

### 🔧 Changed
- Migrated from single script to modular handlers
- Improved error handling and logging
- Better separation of concerns
- Easier to extend and maintain
- More efficient API usage

### 📚 Documentation
- Created comprehensive README
- Added code documentation
- Included usage examples
- Published architecture guide

---

## [1.0.0] - 2026-03-01

### 🎉 Initial Release

First public release of GitHub Security Audit.

### 🚀 Features
- Single monolithic audit script
- Basic security checks:
  - Secret scanning status
  - Dependabot configuration
  - Branch protection rules
- CSV output format
- Simple reporting

### 📝 Documentation
- Basic README with usage instructions
- Installation guide
- Example commands

---

## Version History Summary

| Version | Date | Major Changes |
|---------|------|---------------|
| **2.1.0** | 2026-03-04 | Security improvement automation, bug fixes, comprehensive docs |
| **2.0.0** | 2026-03-03 | Modular architecture, master orchestrator, multiple formats |
| **1.0.0** | 2026-03-01 | Initial release, basic functionality |

---

## Upgrade Guide

### From 2.0.0 to 2.1.0

**No breaking changes.** New features are additions only.

To use new automation features:

```bash
# Pull latest changes
git pull origin main

# Make new scripts executable
chmod +x scripts/apply_security_improvements.sh
chmod +x scripts/enable_*.sh

# Run improvements
./scripts/apply_security_improvements.sh YOUR_OWNER
```

### From 1.0.0 to 2.0.0

**Breaking changes** - Complete architecture change.

Migration steps:

1. **Backup old reports:**
   ```bash
   cp -r reports/ reports_v1_backup/
   ```

2. **Update to new version:**
   ```bash
   git pull origin main
   ```

3. **Use new master script:**
   ```bash
   # Old (v1.0):
   ./github_security_audit.sh YOUR_OWNER

   # New (v2.0+):
   ./scripts/audit_master.sh YOUR_OWNER reports
   ```

4. **Update any automation:**
   - Cron jobs need new command
   - CI/CD pipelines need updates
   - Report parsing may need adjustment (new format)

---

## Planned Features

### Version 2.2.0 (Future)

- [ ] HTML report generation
- [ ] Dashboard visualization
- [ ] Historical trend tracking
- [ ] Automated remediation workflows
- [ ] Compliance report templates (SOC 2, ISO 27001)
- [ ] Multi-organization parallel audits
- [ ] Custom handler marketplace

### Version 3.0.0 (Future)

- [ ] Web UI for viewing reports
- [ ] Real-time monitoring
- [ ] Webhook integrations
- [ ] Slack/Teams notifications
- [ ] API server mode
- [ ] Plugin system
- [ ] Advanced security checks:
  - Commit signing verification
  - License compliance scanning
  - Vulnerability detection
  - SBOM generation

---

## Contributing

Want to contribute? See [[Contributing]] for guidelines.

Contributions welcome for:
- Bug fixes
- New handlers
- Documentation improvements
- Feature enhancements
- Test coverage

---

## Release Process

### How Releases Are Made

1. **Development** on feature branches
2. **Testing** in isolated environment
3. **Code review** by maintainers
4. **Merge** to main branch
5. **Tag** release with version number
6. **Update** changelog
7. **Publish** release notes

### Semantic Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** version: Incompatible API changes
- **MINOR** version: Backward-compatible new features
- **PATCH** version: Backward-compatible bug fixes

Example: `2.1.0`
- `2` = Major version (modular architecture)
- `1` = Minor version (added automation scripts)
- `0` = Patch version

---

## Support

### Getting Help

- **Issues**: File on GitHub for bugs/features
- **Discussions**: Ask questions in GitHub Discussions
- **Wiki**: Check [[FAQ]] and other wiki pages
- **Security**: See [[Security Review]] for security questions

### Reporting Bugs

When filing issues, include:

1. **Version**: `git describe --tags`
2. **OS**: macOS, Linux distro, etc.
3. **Commands**: Exact commands run
4. **Output**: Error messages (remove sensitive info)
5. **Expected**: What should have happened

---

## License

This project is licensed for personal, educational, and internal non-commercial use. Commercial use requires prior written permission. See [LICENSE](../LICENSE) for details.

---

## Acknowledgments

### Dependencies

- [GitHub CLI](https://cli.github.com/) - Official GitHub command-line tool
- [jq](https://stedolan.github.io/jq/) - JSON processor for bash

### Inspiration

Thanks to the GitHub security community for best practices and feedback.

---

## Related Documentation

- [[Home]] - Wiki home page
- [[Installation]] - Setup instructions
- [[Usage Guide]] - How to use the tool
- [[FAQ]] - Frequently asked questions

---

**Last Updated:** March 4, 2026  
**Current Version:** 2.1.0  
**Project Status:** Active Development
