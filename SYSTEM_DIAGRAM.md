# GitHub Security Audit - System Diagram

## 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    MASTER ORCHESTRATOR                          │
│              (audit_master.sh)                                  │
│  - Validates prerequisites                                      │
│  - Coordinates handlers                                         │
│  - Aggregates statistics                                        │
│  - Generates unified reports                                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ sources
                            ▼
            ┌──────────────────────────────┐
            │   COMMON LIBRARY             │
            │   (lib/common.sh)            │
            │                              │
            │  • log_info()                │
            │  • log_success()             │
            │  • log_error()               │
            │  • check_prerequisites()     │
            │  • get_repos()               │
            │  • ensure_report_dir()       │
            └──────────────────────────────┘
                            ▲
                            │ uses
                 ┌──────────┼──────────┬────────────┬──────────┐
                 │          │          │            │          │
                 ▼          ▼          ▼            ▼          ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ Secret   │ │Dependabot│ │ Branch   │ │  Code    │ │  Repo    │
        │ Scanning │ │          │ │Protection│ │ Scanning │ │ Config   │
        │          │ │          │ │          │ │          │ │          │
        │ Handler  │ │ Handler  │ │ Handler  │ │ Handler  │ │ Handler  │
        └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘
             │            │              │           │          │
            CSV   +      CSV   +        CSV   +     CSV   +    CSV   +
           JSON           JSON          JSON        JSON       JSON
             │            │              │           │          │
             └────────────┴──────────────┴───────────┴──────────┘
                            │
             Aggregate Statistics
             Combined Results
                       │
                       ▼
        ┌──────────────────────────────┐
        │    REPORT GENERATION         │
        │                              │
        │  • Markdown Report           │
        │  • JSON Statistics           │
        │  • Combined CSV (optional)   │
        └──────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │   OUTPUT REPORTS             │
        │                              │
        │  reports/                    │
        │  ├─ *_report_*.md            │
        │  ├─ *_stats_*.json           │
        │  └─ *_combined_*.csv         │
        └──────────────────────────────┘
```

---

## 🔄 Data Flow

```
                    ┌─────────────────────┐
                    │  RUN master.sh      │
                    │                     │
                    │ ./scripts/          │
                    │ audit_master.sh     │
                    │ nsoni44 reports     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Prerequisite Checks│
                    │  • gh installed?    │
                    │  • gh authenticated?│
                    │  • jq installed?    │
                    └──────────┬──────────┘
                               │
            ┌──────────────────┼──────────────────┬─────────────────┐
            │                  │                  │                 │
            ▼                  ▼                  ▼                 ▼
       ┌─────────────┐   ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
       │ Secret      │   │ Dependabot   │   │ Branch       │  │ Code         │
       │ Scanning    │   │ Handler      │   │ Protection   │  │ Scanning     │
       │ Handler     │◄──┤ RUNS         │───┤ Handler      │◄─┤ Handler      │
       │             │   │ (60 repos)   │   │ RUNS         │  │ RUNS         │
       │ STDOUT:CSV  │   │              │   │              │  │              │
       │ STDERR:JSON │   │ STDOUT:CSV   │   │ STDOUT:CSV   │  │ STDOUT:CSV   │
       └──────┬──────┘   │ STDERR:JSON  │   │ STDERR:JSON  │  │ STDERR:JSON  │
              │          └──────┬───────┘   └──────┬───────┘  └──────┬───────┘
              │                 │                  │                 │
              │            ┌────▼─────┐           │                 │
              │            │ Repo     │           │                 │
              │            │ Config   │           │                 │
              │            │ Handler  │◄──────────┼─────────────────┘
              │            │ RUNS     │           │
              │            │          │    ┌──────▼──────┐
              │            │ STDOUT:CSV    │ Aggregate   │
              │            │ STDERR:JSON   │ Statistics  │
              └────────────┼──────┬───────┴──────┬───────┘
                           │      │              │
                           └──────┼──────────────┘
                                  │
                      ┌───────────▼────────────┐
                      │  Generate Reports:    │
                      │                       │
                      │  1. Markdown Report   │
                      │     (human-readable)  │
                      │                       │
                      │  2. JSON Stats        │
                      │     (machine-readable)│
                      │                       │
                      │  3. Combined CSV      │
                      │     (data export)     │
                      └───────────┬───────────┘
                                  │
                      ┌───────────▼──────────────┐
                      │  Save to:                │
                      │                          │
                      │  reports/                │
                      │  ├─ *_report_*.md       │
                      │  ├─ *_stats_*.json      │
                      │  └─ *_combined_*.csv    │
                      │                          │
                      └──────────┬───────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │  [Optional]             │
                    │  Email Notification     │
                    │  (if EMAIL_TO provided) │
                    └────────────────────────┘
```

---

## 📊 Handler Processing Pipeline

### Each Handler Processes:

```
┌─────────────────────────────────────────────────┐
│  INPUT: GitHub Owner (e.g., nsoni44)           │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
       ┌─────────────────────────┐
       │  Load Common Library    │
       │  (lib/common.sh)        │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ Validate Prereqs:       │
       │ • gh CLI installed?     │
       │ • User authenticated?   │
       │ • jq available?         │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ Fetch Repos             │
       │ gh repo list nsoni44    │
       │ Returns: 10 repos       │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ For Each Repo:          │
       │ • Decode Base64         │
       │ • Extract nameWithOwner │
       │ • Extract visibility    │
       │ • Extract archived flag │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ Query Security Data:    │
       │ gh api repos/REPO/...   │
       │ Extract security fields │
       │ (varies per handler)    │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ Format Output:          │
       │ repo,field1,field2,...  │
       │ (CSV to stdout)         │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ Track Statistics:       │
       │ total repos             │
       │ enabled/configured      │
       │ count metrics           │
       └────────────┬────────────┘
                    │
                    ▼
       ┌─────────────────────────┐
       │ Output Statistics JSON  │
       │ (to stderr)             │
       │ {                       │
       │   "handler": "...",     │
       │   "total": 10,          │
       │   "metric1": 9,         │
       │   "metric2": N          │
       │ }                       │
       └────────────┬────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│  OUTPUT:                                     │
│  → STDOUT: CSV rows (one per repo)          │
│  → STDERR: JSON statistics                  │
└──────────────────────────────────────────────┘
```

---

## 🎯 Security Domains Covered

```
┌─────────────────────────────────────────────────────────┐
│          GITHUB SECURITY AUDIT COVERAGE                 │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1️⃣  SECRET SCANNING & PUSH PROTECTION                 │
│     ├─ Secret scanning status                          │
│     └─ Push protection status                          │
│                                                         │
│  2️⃣  DEPENDENCY MANAGEMENT                             │
│     ├─ Security updates enabled                        │
│     └─ Version updates configured                      │
│                                                         │
│  3️⃣  BRANCH PROTECTION                                 │
│     ├─ Protection rules active                         │
│     ├─ Code review requirements                        │
│     └─ Status check enforcement                        │
│                                                         │
│  4️⃣  CODE SCANNING (GHAS)                              │
│     ├─ Code scanning enabled                           │
│     ├─ CodeQL configured                               │
│     └─ Active security alerts                          │
│                                                         │
│  5️⃣  REPOSITORY CONFIGURATION                          │
│     ├─ Has description                                 │
│     ├─ Has homepage                                    │
│     ├─ Wiki enabled                                    │
│     ├─ Pages enabled                                   │
│     ├─ Forking allowed                                 │
│     └─ Downloads allowed                               │
│                                                         │
└─────────────────────────────────────────────────────────┘

           160+ Security Metrics per Audit
           Per Repository: ~16 data points
           10 Repos: 160 metrics collected
           5 Handlers × 10 Repos = Complete Coverage
```

---

## 📈 Metrics Collected Per Handler

```
┌──────────────────────────────────────────┐
│ SECRET_SCANNING Handler                  │
├──────────────────────────────────────────┤
│ Per Repo:                                │
│  - secret_scanning_enabled: yes/no       │
│  - push_protection_enabled: yes/no       │
│                                          │
│ Statistics:                              │
│  - total repos analyzed: N               │
│  - secret_scanning_enabled: count        │
│  - push_protection_enabled: count        │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ DEPENDABOT Handler                       │
├──────────────────────────────────────────┤
│ Per Repo:                                │
│  - security_updates: enabled/na          │
│  - version_updates: configured/not...    │
│                                          │
│ Statistics:                              │
│  - total repos analyzed: N               │
│  - security_updates_enabled: count       │
│  - version_updates_configured: count     │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ BRANCH_PROTECTION Handler                │
├──────────────────────────────────────────┤
│ Per Repo:                                │
│  - protection_enabled: true/false        │
│  - requires_reviews: true/false          │
│  - requires_status_checks: true/false    │
│                                          │
│ Statistics:                              │
│  - total repos analyzed: N               │
│  - protection_enabled: count             │
│  - requires_reviews: count               │
│  - requires_status_checks: count         │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ CODE_SCANNING Handler                    │
├──────────────────────────────────────────┤
│ Per Repo:                                │
│  - scanning_enabled: enabled/unknown     │
│  - codeql_configured: true/false         │
│  - has_alerts: true/false/unknown        │
│                                          │
│ Statistics:                              │
│  - total repos analyzed: N               │
│  - scanning_enabled: count               │
│  - codeql_configured: count              │
│  - repos_with_alerts: count              │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│ REPO_CONFIG Handler                      │
├──────────────────────────────────────────┤
│ Per Repo:                                │
│  - has_description: true/false           │
│  - has_homepage: true/false              │
│  - wiki_enabled: true/false              │
│  - pages_enabled: true/false             │
│  - forking_allowed: true/false           │
│  - downloads_allowed: true/false         │
│                                          │
│ Statistics:                              │
│  - total repos analyzed: N               │
│  - with_description: count               │
│  - with_homepage: count                  │
│  - wiki_enabled: count                   │
│  - pages_enabled: count                  │
│  - forking_allowed: count                │
│  - downloads_allowed: count              │
└──────────────────────────────────────────┘
```

---

## 🔄 Integration Points

```
┌─────────────────────────────────────────┐
│      audit_master.sh                    │
│  (Central Orchestration Point)          │
└────────────────┬────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
    Generates         Can Send
        │                 │
        ▼                 ▼
    Reports          Email
   ├─ .md         (mail command)
   ├─ .json
   └─ .csv
        │
        └─→ Can be integrated with:
            • CI/CD pipelines
            • Monitoring dashboards
            • Compliance tools
            • SIEM systems
            • Webhooks
```

---

## 📚 File Relationships

```
Main Entry Point:
scripts/
  └─ audit_master.sh ──── orchestrates everything

Shared Utilities:
lib/
  └─ common.sh ────────── used by all handlers

Individual Handlers:
handlers/
  ├─ secret_scanning.sh ──┐
  ├─ dependabot.sh ───────┤─→ All source lib/common.sh
  ├─ branch_protection.sh │   and output CSV + JSON
  ├─ code_scanning.sh ────┤
  └─ repo_config.sh ──────┘

Output:
reports/
  ├─ github_security_audit_report_*.md
  ├─ github_security_audit_stats_*.json
  └─ github_security_audit_combined_*.csv

Documentation:
├─ QUICKSTART.md ────── Get started guide
├─ ARCHITECTURE.md ───── Technical reference
└─ EXPANSION_SUMMARY.md ─ Project overview
```

---

## 🚀 Execution Timeline

```
T+0s    Master script starts
        └─ Prerequisite checks (1-2s)

T+2s    Handler: secret_scanning
        └─ Fetch 10 repos, query each (5-8s)
        └─ Output: CSV + JSON stats

T+10s   Handler: dependabot
        └─ Fetch 10 repos, query each (5-8s)
        └─ Output: CSV + JSON stats

T+18s   Handler: branch_protection
        └─ Fetch 10 repos, query each (5-8s)
        └─ Output: CSV + JSON stats

T+26s   Handler: code_scanning
        └─ Fetch 10 repos, query each (8-12s)
        └─ Output: CSV + JSON stats

T+38s   Handler: repo_config
        └─ Fetch 10 repos, query each (8-12s)
        └─ Output: CSV + JSON stats

T+50s   Report Generation
        └─ Aggregate stats (1s)
        └─ Generate Markdown (1s)
        └─ Generate JSON (1s)

T+53s   Optional: Email
        └─ Send email notification (2-5s)

T+58s   ✅ Complete!
        Total time: ~60 seconds
```

---

**Created:** March 4, 2026  
**Version:** 2.0 - Modular Architecture
