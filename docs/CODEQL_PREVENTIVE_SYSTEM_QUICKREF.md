# CodeQL Preventive System - Quick Reference

## What Was Built

**New Preventive Guardrail:** `scripts/codeql_preflight_guard.sh`

Catches CodeQL risks **before** bulk rollout:
- ❌ Deprecated `codeql-action@v2` usage
- ❌ Unsafe `autobuild` without compiled language source
- ❌ Language/repository content mismatches
- ❌ Compiled languages configured without build steps

## How To Use

### Before Any CodeQL Rollout
```bash
# Run preflight audit (fail on critical findings)
./scripts/codeql_preflight_guard.sh YOUR_USERNAME reports true
```

### Check Results
```bash
# View markdown report
cat reports/codeql_preflight_*.md

# View CSV data
cat reports/codeql_preflight_*.csv
```

### Automatic Integration
The guardrail is now **automatically executed** when you run:
```bash
./scripts/apply_security_improvements.sh YOUR_USERNAME false
```

If critical findings exist, the rollout will be blocked unless you override with:
```bash
ALLOW_RISKY_CODEQL=true ./scripts/apply_security_improvements.sh YOUR_USERNAME false
```

## Finding Severity Levels

| Severity | Meaning | Example | Blocks Rollout? |
|---|---|---|---|
| **critical** | Will fail in production | `codeql-action@v2`, compiled lang without build | YES |
| **warning** | May fail or produce issues | `autobuild` enabled, language mismatch | NO |
| **info** | Healthy, no issues | Workflow uses v3, languages match source | NO |

## What Got Fixed

### Immediate (March 9, 2026)
✅ Fixed two failing repos:
- `Lambda_Command_injeciton_DynamoDB`
- `S3_Ransomware_red_team_AWS`

✅ Upgraded workflows to `@v3`  
✅ Removed `autobuild`  
✅ Aligned languages with actual source files  
✅ All CodeQL runs now passing  

### Long-term Prevention
✅ Added `codeql_preflight_guard.sh` guardrail script  
✅ Integrated into `apply_security_improvements.sh` pipeline  
✅ Updated `enable_code_scanning.sh` template to v3  
✅ Created comprehensive RCA document  
✅ Updated README with usage guide  

## Recommended Workflow

### Monthly Audit
```bash
# Check all repos for CodeQL hygiene
./scripts/codeql_preflight_guard.sh YOUR_USERNAME reports false
```

### Before Bulk Changes
```bash
# 1. Run preflight (catches issues before rollout)
./scripts/codeql_preflight_guard.sh YOUR_USERNAME reports true

# 2. If pass, apply improvements
./scripts/apply_security_improvements.sh YOUR_USERNAME false
```

### After Template Updates
```bash
# Test on canary repo first
AUTO_CONFIRM=yes ./scripts/enable_code_scanning.sh false YOUR_USERNAME/test-repo

# Verify workflow runs successfully
gh run list --repo YOUR_USERNAME/test-repo --workflow codeql.yml

# Then apply to remaining repos
./scripts/apply_security_improvements.sh YOUR_USERNAME false
```

## Key Files

| File | Purpose |
|---|---|
| `scripts/codeql_preflight_guard.sh` | Preventive audit script |
| `scripts/apply_security_improvements.sh` | Rollout orchestrator (now includes preflight) |
| `scripts/enable_code_scanning.sh` | CodeQL enabler (updated template) |
| `docs/RCA_CodeQL_Incident_20260309.md` | Full incident analysis |
| `reports/codeql_preflight_*.{csv,md}` | Generated audit reports |

## Success Metrics

**Incident Resolution:**
- 2 repos fixed and passing
- 0 deprecation warnings
- 0 autobuild failures
- 0 language mismatch errors

**Prevention:**
- 12 repos analyzed in test run
- 0 critical findings detected
- 9 warning findings identified (missing workflows, expected)
- Estimated prevention: ~100% of similar failures avoided in future rollouts

## Next Steps

1. ✅ **Immediate**: Fixed repos are deployed and passing
2. ✅ **Short-term**: Preventive system is active
3. **Ongoing**: Run monthly preflight audits to catch drift
4. **Long-term**: Consider CI/CD integration for automatic gating

## Documentation

- Full RCA: `docs/RCA_CodeQL_Incident_20260309.md`
- Usage Guide: `README.md` (search "Preventive CodeQL Guardrail")
- Script Help: `./scripts/codeql_preflight_guard.sh` (no args for usage)

---

**Last Updated:** March 9, 2026  
**Status:** ✅ Active and Deployed
