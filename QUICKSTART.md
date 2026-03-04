# SVETRI - Quick Start Guide

**GitHub Security Intelligence - Professional Security Audit Tool**

```
....                                                                  
...................                                                   
............                                                          
..........                                                            
.........                            .                                
........                            ..     .   .                      
........                           .''      ......                    
```

This is a **professional Github security audit system** that automatically scans your repositories across 5 major security domains and generates comprehensive reports.

---

## Quick Start (30 seconds)

### 1. Verify Prerequisites
```bash
gh auth status  # GitHub CLI must be authenticated
which jq        # jq JSON processor should be installed
```

### 2. Run Full Audit
```bash
cd /Users/nsoni/Downloads/My_Project/Github
./scripts/audit_master.sh nsoni44 reports
```

### 3. Check Reports
```bash
ls -lh reports/github_security_audit_*.{md,json}
cat reports/github_security_audit_report_*.md
```

---

## Architecture

### Directory Structure
```
.
├── scripts/
│   ├── audit_master.sh              ← Master orchestrator (RUN THIS)
│   └── github_security_audit.sh     ← Legacy all-in-one script
├── handlers/                         ← Individual security checkers
│   ├── secret_scanning.sh           ← Checks secrets scanning & push protection
│   ├── dependabot.sh                ← Checks Dependabot configuration
│   ├── branch_protection.sh         ← Checks branch protection rules
│   ├── code_scanning.sh             ← Checks code scanning (GHAS)
│   └── repo_config.sh               ← Checks repository settings
├── lib/
│   └── common.sh                     ← Shared utilities & logging
├── reports/                          ← Generated reports
│   ├── github_security_audit_report_*.md      ← Human-readable
│   └── github_security_audit_stats_*.json     ← Machine-readable
└── ARCHITECTURE.md                  ← Detailed documentation
```

---

## Usage Patterns

### Pattern 1: Full Audit with All Handlers
```bash
./scripts/audit_master.sh nsoni44 reports
```
**Generates:**
- Markdown report with all security metrics
- JSON statistics file
- Combined CSV output

### Pattern 2: Individual Handler (for Debugging)
```bash
./handlers/secret_scanning.sh nsoni44
```
**Output:**
- CSV data to stdout
- Statistics JSON to stderr

### Pattern 3: Save Individual Handler Output
```bash
./handlers/dependabot.sh nsoni44 csv > my_dependabot_report.csv
```

### Pattern 4: Run with Email Notification
```bash
./scripts/audit_master.sh nsoni44 reports security-team@company.com
```

---

## What Each Handler Does

| Handler | Purpose | Metrics |
|---------|---------|---------|
| **secret_scanning.sh** | GitHub Secret Scanning | Secret scanning enabled, Push protection enabled |
| **dependabot.sh** | Dependency management | Dependabot security updates, Version updates |
| **branch_protection.sh** | Branch safety rules | Protection enabled, Reviews required, Status checks |
| **code_scanning.sh** | SAST security analysis | Code scanning enabled, CodeQL configured, Alerts |
| **repo_config.sh** | Repository settings | Description, Homepage, Wiki, Pages, Forking, Downloads |

---

## Report Examples

### Generated Report: `github_security_audit_report_*.md`
```markdown
# GitHub Security Audit Report

**Owner:** nsoni44
**Generated:** Wed Mar 4 00:03:48 EET 2026
**Total Repositories:** 10

## Summary Statistics

### secret_scanning
- Total: 10
- Secret scanning enabled: 9
- Push protection enabled: 9

### dependabot
- Total: 10
- Security updates enabled: 9
- Version updates configured: 0

... [detailed results for each repo] ...
```

### Generated Stats: `github_security_audit_stats_*.json`
```json
{
  "metadata": {
    "owner": "nsoni44",
    "timestamp": "20260304_000307",
    "generated": "Wed Mar  4 00:03:48 EET 2026",
    "total_repositories": 10
  },
  "handlers": {
    "secret_scanning": {
      "handler": "secret_scanning",
      "total": 10,
      "secret_scanning_enabled": 9,
      "push_protection_enabled": 9
    },
    ...
  }
}
```

---

## Installation / Setup

### Prerequisites Check
```bash
# Must have GitHub CLI installed and authenticated
gh auth status

# Must have jq for JSON processing
brew install jq  # or apt-get install jq on Linux
```

### Make Scripts Executable
```bash
cd /Users/nsoni/Downloads/My_Project/Github
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
```

### Verify Installation
```bash
./scripts/audit_master.sh nsoni44 reports
# Should run without errors and generate reports/
```

---

## Advanced Usage

### Create Custom Handler
Want to audit a specific feature? Copy a handler:

```bash
cp handlers/secret_scanning.sh handlers/my_custom_audit.sh
```

Edit the script to your needs, then add `my_custom_audit` to the `HANDLERS` array in `audit_master.sh`.

### Integrate with CI/CD
Add to GitHub Actions:
```yaml
- name: Run Security Audit
  run: |
    cd github-security-audit
    ./scripts/audit_master.sh ${{ github.repository_owner }} reports
```

### Schedule Daily Audits
Add to crontab:
```bash
0 2 * * * cd /path/to/audit && ./scripts/audit_master.sh owner reports
```

---

## Troubleshooting

### Error: "gh is not authenticated"
```bash
gh auth login
```

### Error: "jq: command not found"
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Error: "Permission denied"
```bash
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
```

### No Reports Generated
Check if handlers have output:
```bash
./handlers/secret_scanning.sh nsoni44 2>&1 | head
```

---

## File Structure Reference

| File | Purpose |
|------|---------|
| `audit_master.sh` | **Main entry point** - orchestrates all handlers |
| `handlers/*.sh` | Individual security audit modules |
| `lib/common.sh` | Shared functions and utilities |
| `ARCHITECTURE.md` | Full technical documentation |
| `reports/*.md` | Human-readable audit reports |
| `reports/*.json` | Machine-readable statistics |

---

## Key Features

✅ **Modular Design** - Each security aspect is independent  
✅ **Master Orchestration** - Single command runs all audits  
✅ **Multiple Formats** - CSV, Markdown, JSON output  
✅ **Error Handling** - Graceful failure and logging  
✅ **Color-coded Output** - Easy to read terminal output  
✅ **Extensible** - Easy to add new handlers  
✅ **Email Support** - Send reports automatically  

---

## Next Steps

1. **Run your first audit:**
   ```bash
   ./scripts/audit_master.sh nsoni44 reports
   ```

2. **Review results:**
   ```bash
   cat reports/github_security_audit_report_*.md
   ```

3. **Schedule regular audits** using cron or CI/CD

4. **Create custom handlers** for additional checks

5. **Integrate with alerting** systems

---

## Support & Documentation

- Full technical details: See [ARCHITECTURE.md](ARCHITECTURE.md)
- For handler source code examples: Check `handlers/` directory
- For utility functions: Review `lib/common.sh`

---

**Version:** 2.0 (Modular)  
**Last Updated:** March 4, 2026  
**Status:** ✅ Production Ready
