# GitHub Security Audit Wiki

Welcome to the GitHub Security Audit project wiki! This comprehensive guide covers everything you need to know about setting up, using, and extending this modular security audit system.

## 📚 Quick Navigation

**Getting Started:**
- [[Home]] - Project overview
- [[Installation]] - Setup and prerequisites
- [[Quick Start]] - 5-minute quick start guide

**Usage & Examples:**

**Security Improvements:**
- [[Improvements Guide]] - Apply security best practices

**Usage & Examples:**
**Architecture & Development:**
- [[Architecture]] - System design and architecture
- [[Handler Development]] - Creating custom handlers
- [[API Reference]] - Functions and interfaces

**Operations:**
- [[Troubleshooting]] - Common issues and solutions
- [[Best Practices]] - Operational best practices
- [[Security Review]] - Security and safety considerations

**Project Information:**
- [[FAQ]] - Frequently asked questions
- [[Contributing]] - How to contribute
- [[Changelog]] - Version history
- [[License]] - Project license

---

## 🎯 What is GitHub Security Audit?

A **modular, production-ready system** for auditing GitHub repositories across multiple security domains:

- 🔐 Secret Scanning & Push Protection
- 📦 Dependency Management (Dependabot)
- 🔒 Branch Protection Rules
- 🔍 Code Scanning (GHAS)
- ⚙️ Repository Configuration

Generate comprehensive security reports in **Markdown**, **JSON**, and **CSV** formats.

---

## ✨ Key Features

✅ **Modular Architecture** - Independent handlers for each security domain  
✅ **Master Orchestration** - Single command runs all audits  
✅ **Multi-format Reports** - CSV, Markdown, JSON output  
✅ **160+ Metrics** - Comprehensive security coverage  
✅ **Extensible** - Easy to add custom handlers  
✅ **Production Ready** - Error handling, logging, validation  
✅ **Well Documented** - Complete guides and examples  

---

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/github-security-audit.git
cd github-security-audit

# Install prerequisites
brew install gh jq  # macOS
# or: sudo apt-get install gh jq  # Ubuntu/Debian

# Authenticate with GitHub
gh auth login

# Run audit
./scripts/audit_master.sh YOUR_GITHUB_OWNER reports

# View results
cat reports/github_security_audit_report_*.md
```

For detailed instructions, see [[Installation]].

---

## 📖 Main Documentation

### For First-Time Users
Start here: [[Quick Start]] → [[Installation]] → [[Usage Guide]]

### For Operators
Try these: [[Usage Guide]] → [[Best Practices]] → [[Troubleshooting]]

### For Developers
Read these: [[Architecture]] → [[Handler Development]] → [[Contributing]]

### For Deployment
Check out: [[Installation]] → [[Best Practices]] → [[Security Review]]

---

## 📊 What Gets Audited?

**Per Repository (10 repos = 160+ metrics):**

| Handler | Metrics | Example |
|---------|---------|---------|
| Secret Scanning | 2 | Scanning enabled, Push protection enabled |
| Dependabot | 2 | Security updates, Version updates |
| Branch Protection | 3 | Rules active, Code reviews, Status checks |
| Code Scanning | 3 | Scanning enabled, CodeQL, Alerts |
| Repo Config | 6 | Description, Wiki, Pages, Forking, etc. |

---

## 🏗️ System Architecture

```
audit_master.sh (Master Orchestrator)
    ├─ secret_scanning.sh (Push protection audit)
    ├─ dependabot.sh (Dependency management)
    ├─ branch_protection.sh (Branch safety)
    ├─ code_scanning.sh (SAST/CodeQL)
    └─ repo_config.sh (Repository settings)
```

All handlers run in sequence, report statistics, and results are aggregated into unified reports.

See [[Architecture]] for detailed diagrams and flow charts.

---

## 📝 Reports Generated

**Three Output Formats:**

1. **Markdown Report** (`*_report_*.md`)
   - Human-readable format
   - Summary statistics
   - Detailed per-repo results
   - Suitable for documentation

2. **JSON Statistics** (`*_stats_*.json`)
   - Machine-readable format
   - Easy integration with tools
   - Suitable for automation/dashboards

3. **Combined CSV** (`*_combined_*.csv`)
   - Data export format
   - Easy import to spreadsheets
   - Suitable for analysis

---

## 🔧 Common Tasks

**Run Daily Audits:**
```bash
0 2 * * * /path/to/audit_master.sh YOUR_OWNER reports
```

**Run with Email Notification:**
```bash
./scripts/audit_master.sh YOUR_OWNER reports your@email.com
```

**Run Individual Handlers:**
```bash
./handlers/secret_scanning.sh YOUR_OWNER
./handlers/dependabot.sh YOUR_OWNER
```

**Add to CI/CD:**
```yaml
- name: Security Audit
  run: ./scripts/audit_master.sh ${{ github.repository_owner }} reports
```

See [[Usage Guide]] for more examples.

---

## ❓ Questions?

- **Getting started?** → [[Quick Start]]
- **Having issues?** → [[Troubleshooting]]
- **Want to extend?** → [[Handler Development]]
- **Unsure about safety?** → [[Security Review]]
- **Other questions?** → [[FAQ]]

---

## 📄 License

This project is provided under [MIT License](../LICENSE) - free for personal and commercial use.

---

## 🤝 Contributing

Contributions welcome! See [[Contributing]] for guidelines.

---

**Last Updated:** March 4, 2026  
**Current Version:** 2.0 (Modular)
