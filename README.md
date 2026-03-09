# SVETRI - GitHub Security Intelligence

```
....                                                                  
...................                                                   
............                                                          
..........                                                            
.........                            .                                
........                            ..     .   .                      
........                           .''      ......                    
........                   ....   ..,;..    ......                    
.......                  ..';:lll:::ll;;,,'.. ...                     
......                  ..',:ldxkkxxdddkOOOd:,...                     
......                  ..',:ldxkO00KKKKXXX0dko:..                    
.....                  ...',:ldkOO0KKKKXXNNXkX0d;....                 
 ...                   ...',:cdkO0KKKKKXXNNNK0Xk; ....                
                       ...',:ldkO0KKKKXXXNNXOKXO, .....               
                       ....,:ldk0000KKXXNNNNX0Ok'  .....              
                      .......':dk0000KKK0000KKkx.  ......             
                    ...    ....;okO00Od:,;cx00xc .  .....             
                    .......':...,oOKOo,..';;dO0; .. ......            
                    ..,,,,,;;,..'dXX0d::cdxk0XK.  .........           
                    ..';clllc;'.,kNNNX0OOKXNNNl   .........           
                     ..,clooc'..c0NXXXXXNNNNN0.   ..........          
                     ..,:lodc..;dKNXKO0KXXXXK'     .........          
                     ..';ccc;,.,lOKXXOO0KXKO:      .........          
                      ..;:;'.',ldkXXXOkO00k'       ..........         
      ..               .';,'..,:lldxOOkOk:.         .........         
                     .   .'';:cloxk00Od;.           .........         
                   . ..   ..;ldOKXX0kc.             .........         
  .....     .         ...   .,ldxkxdo:'.             ...'.....        
........   ..       . ........lodxkxoc,.             ....'.....       
.',''''..  .        .. ....'''okkOOkxl'.              ....''.'.       
;:,'',;;.           .. ....,,'lkkkkxdc'.               ....'''..      
ooc::c;,..           .. ..'',;cxOOkkxo;.           .     ...''.'.     
odddkOOdc..            ...',':lxO00Okoc'.     .   ....    .'.''...    
lOOO0K0x;.            .....'';lxkOxdddl:.   ...   .....  .,.,''...    
kx00KKOo'.              ....,,:dk0KKKko,.. ....  ....   ..'..,,....   
00OKXKx:.         .....  ....,;lokO00k;.... ..  ...........''';...    
KX0OX0d..        . ..........';:lxKX0c'...  ....... ......','';....   
XNXk0Oo.           ...........,:o0K0o'....   .....     ...',,,;...    
KNXkkO:.     .     .........'.,cxK0d;'..    ....    .....'',:;:.      
XX0kod,.  .... ... .........',:okOkl;'.    ......  ..''..',;::c'      
XKOdcl'....... ... ........:cclldddd:'.    .... .  ..,;;'',::c:,.     
K0ko,:...  ..........'.'',,locccok0k:'.    .........';:c;,:::cc,.     
KOdc''.   ... ......'''',;::l:ldOXXO;..    .........':c:;c:lclc'..    
K0o;...   ... ......''',;;cdllxOXXXo'.............,;;:c::olllc:...    
KKd'...  ... .......'',;:loxxxOKXXx'....'',....'',:cc;clolllll;...    
ok0;.. . ..........'',;;llox0KXNN0'. .,,,,,'',',::lll:cdkoollc,...    
c:d:  .  ..........'',;;:okOKXNXKo ..,;c;,,',,,;:colodcxOoolc:'..     
```

**SVETRI :: GitHub Security Intelligence**

*Professional-grade security audit system for GitHub repositories*

[![License](https://img.shields.io/badge/License-Personal%20Use%20Only-orange.svg)](LICENSE)
[![Bash 4.0+](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![GitHub CLI](https://img.shields.io/badge/Requires-GitHub--CLI-black.svg)](https://cli.github.com)
[![Production Ready](https://img.shields.io/badge/Status-Production--Ready-blue.svg)](docs/ARCHITECTURE.md)

Comprehensive, modular security audit system for GitHub repositories with coverage across **5 major security domains** and **160+ metrics**.

## 🎯 SVETRI Features

**Comprehensive Security Auditing:**
- 🔐 **Secret Scanning** - Real-time secret detection & push protection
- 📦 **Dependency Management** - Dependabot version & security updates
- 🔒 **Branch Protection** - Code review requirements, force-push prevention
- 🔍 **Code Scanning** - Advanced CodeQL analysis & vulnerability detection
- ⚙️ **Repository Config** - Settings, privacy, and metadata verification

**Professional Reports:**
- 📊 **160+ Security Metrics** - Per-repository coverage
- 📈 **Multi-format Output** - Markdown, JSON, CSV reports
- 🎯 **Executive Summary** - High-level security overview
- 📋 **Detailed Analysis** - Per-domain breakdown & recommendations

**Enterprise Ready:**
- ✅ **Production Grade** - Error handling, validation, logging
- 🚀 **CI/CD Integration** - GitHub Actions, GitLab CI, Jenkins
- 🔧 **Extensible Architecture** - Easy custom handlers
- 📡 **Automation Ready** - Bulk improvements, scheduled audits
- 🔐 **Security First** - Read-only, no credential storage, transparent

## ⚡ Run Your First Audit (30 seconds)

```bash
# 1. Install prerequisites (if needed)
brew install gh jq

# 2. Clone SVETRI
git clone https://github.com/nsoni44/github-security-audit.git
cd github-security-audit

# 3. Authenticate with GitHub (one-time setup)
gh auth login

# 4. Run SVETRI audit on your repositories
./scripts/audit_master.sh YOUR_GITHUB_USERNAME reports
```

**You'll see the SVETRI banner and a live security audit of all your repositories:**

```
[Output shows SVETRI girl-face ASCII banner]

[INFO] Starting SVETRI security audit for YOUR_GITHUB_USERNAME
[INFO] Running security handlers...

[✓] Handler completed: secret_scanning
[✓] Handler completed: dependabot  
[✓] Handler completed: branch_protection
[✓] Handler completed: code_scanning
[✓] Handler completed: repo_config

[✓] Audit completed successfully!
[INFO] Reports generated:
  - reports/github_security_audit_report_*.md
  - reports/github_security_audit_stats_*.json
```

**Reports are instantly ready** to review in `reports/` folder.

📖 [Full Installation Guide →](wiki/Installation.md)

## 📊 What Gets Audited?

| Security Domain | Metrics | Coverage |
|---|---|---|
See [Usage Guide](wiki/Usage-Guide.md) for more examples.

## 🚀 Apply Security Improvements

After identifying gaps in your audit results, automatically apply security improvements:

```bash
# Preview all improvements (dry run)
./scripts/apply_security_improvements.sh YOUR_USERNAME true

# Apply improvements to all repositories
./scripts/apply_security_improvements.sh YOUR_USERNAME false
```

**Automated improvements include:**
- **Branch Protection** - Require code reviews, prevent force pushes (0→10 enabled)
- **CodeQL Scanning** - Detect vulnerabilities with advanced code analysis (0→10 enabled)
- **Dependabot Updates** - Keep dependencies current with daily update checks (0→10 enabled)

See [Improvements Guide](wiki/Improvements-Guide.md) for detailed step-by-step instructions.

### Preventive CodeQL Guardrail

Run this before bulk changes to catch deprecated CodeQL versions, unsafe autobuild usage, and language/source mismatches:

```bash
./scripts/codeql_preflight_guard.sh YOUR_USERNAME reports true
```

- Generates `reports/codeql_preflight_*.csv` and `reports/codeql_preflight_*.md`
- Exits non-zero when critical findings are detected (with third arg `true`)
- Is automatically executed by `apply_security_improvements.sh`

| **Dependabot** | Security updates, Version updates | 2 |
| **Branch Protection** | Rules active, Code reviews, Status checks | 3 |
| **Code Scanning** | Scanning enabled, CodeQL, Alerts | 3 |
| **Repository Config** | Description, Wiki, Pages, Settings | 6 |
| **TOTAL** | Per repository | **16+ metrics** |

**With 10 repositories: 160+ security data points**

## 📝 Reports Generated

#### 1. Markdown Report (`*_report_*.md`)
Human-readable format with summary statistics and detailed per-repository results.

#### 2. JSON Statistics (`*_stats_*.json`)
Machine-readable format for integration with dashboards and automation tools.

#### 3. Combined CSV (`*_combined_*.csv`)
Spreadsheet-compatible format for data analysis and export.

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│  audit_master.sh (Orchestrator)         │
└────────────────┬────────────────────────┘
                 │
        ┌────────┴─────────┐
        │                  │
   ┌────▼──────┐    ┌─────▼──────┐
   │ Handlers  │    │   Library  │
   ├────────────┤    ├────────────┤
   │ • Secret   │    │ common.sh  │
   │ • Dependab │    │ (Utilities │
   │ • Branch P │    │  & Logging)│
   │ • Code Scn │    └────────────┘
   │ • Repo Cfg │
   └────┬─────────┘
        │
   ┌────▼─────────────────────────┐
   │  Reports                     │
   ├──────────────────────────────┤
   │ • Markdown (human-readable)  │
   │ • JSON (machine-readable)    │
   │ • CSV (data export)          │
   └──────────────────────────────┘
```

## 🚀 Usage Examples

### Basic Audit
```bash
./scripts/audit_master.sh my-username reports
```

### Audit Organization
```bash
./scripts/audit_master.sh my-organization reports
```

### With Email Notification
```bash
./scripts/audit_master.sh my-org reports admin@company.com
```

### Run Individual Handler
```bash
./handlers/secret_scanning.sh my-org
./handlers/dependabot.sh my-org
```

### Schedule Daily Audit
```bash
# Add to crontab
0 2 * * * cd /path && ./scripts/audit_master.sh owner reports
```

### GitHub Actions Integration
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
      - run: sudo apt-get install gh jq
      - run: gh auth login --with-token < <(echo ${{ secrets.GITHUB_TOKEN }})
      - run: ./scripts/audit_master.sh ${{ github.repository_owner }} reports
```

See [Usage Guide](wiki/Usage-Guide.md) for more examples.

## 📚 Documentation

| Page | Purpose |
|------|---------|
| **[Wiki Home](wiki/Home.md)** | Overview and navigation |
| **[Getting Started](wiki/Installation.md)** | Installation & setup |
| **[Usage Guide](wiki/Usage-Guide.md)** | Comprehensive usage |
| **[Improvements Guide](wiki/Improvements-Guide.md)** | Apply security improvements |
| **[Architecture](ARCHITECTURE.md)** | System design |
| **[FAQ](wiki/FAQ.md)** | Common questions |
| **[Contributing](CONTRIBUTING.md)** | How to contribute |

## 🔒 Security

This tool is **audit-only** and completely safe:

- ✅ **Read-only operations** - No modifications to repositories
- ✅ **No credentials stored** - Uses GitHub CLI authentication
- ✅ **No external data transmission** - All processing local
- ✅ **Officially vetted dependencies** - GitHub CLI & jq only
- ✅ **Transparent code** - Open source for review
- ✅ **No telemetry** - Doesn't collect or send usage data

See [SECURITY.md](SECURITY.md) for detailed security information.

## 📋 Requirements

- **Bash 4.0+** (most systems have this)
- **GitHub CLI** (`gh`) - [Install](https://cli.github.com)
- **jq** - [Install](https://stedolan.github.io/jq)
- **GitHub account** - Read access to repositories

## 🛠️ Installation

### macOS
```bash
brew install gh jq
git clone https://github.com/YOUR_USERNAME/github-security-audit.git
cd github-security-audit
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
gh auth login
```

### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install gh jq
git clone https://github.com/YOUR_USERNAME/github-security-audit.git
cd github-security-audit
chmod +x scripts/*.sh handlers/*.sh lib/*.sh
gh auth login
```

### Docker
```bash
docker build -t github-security-audit .
docker run -e GH_TOKEN=$TOKEN \
  -v $(pwd)/reports:/app/reports \
  github-security-audit YOUR_OWNER reports
```

See [Installation Guide](wiki/Installation.md) for detailed setup.

## 💡 Use Cases

- ✅ **Daily Security Audits** - Keep track of security configurations
- ✅ **Compliance Monitoring** - Ensure organizational standards
- ✅ **CI/CD Integration** - Automated security checks
- ✅ **Incident Investigation** - Quick audit after security events
- ✅ **Onboarding** - Verify new repos meet security standards
- ✅ **Reporting** - Generate audit reports for leadership

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to report issues
- How to suggest features
- How to submit code
- How to create custom handlers

## 📄 License

Personal Use License - Personal, educational, and internal non-commercial use only.

Commercial use requires prior written permission. See [LICENSE](LICENSE) for full terms.

## 📞 Support

- 📖 **Documentation**: [Wiki](wiki/Home.md)
- 💬 **Questions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/github-security-audit/discussions)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/YOUR_USERNAME/github-security-audit/issues)
- 🔒 **Security Issues**: See [SECURITY.md](SECURITY.md)

## 🎓 Learn More

- Understand the **[Architecture](ARCHITECTURE.md)**
- Create a **[Custom Handler](wiki/Handler-Development.md)**
- Review **[Best Practices](wiki/Best-Practices.md)**
- Check **[Troubleshooting](wiki/Troubleshooting.md)**

## 🙏 Acknowledgments

- Built with [GitHub CLI](https://cli.github.com)
- JSON processing with [jq](https://stedolan.github.io/jq/)
- Inspired by security best practices

---

**Made with ❤️ for GitHub security**

⭐ If this project helps you, please consider giving it a star!
