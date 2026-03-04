# Contributing to GitHub Security Audit

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## 🎯 How to Contribute

### Report Issues

Found a bug or problem? Please help us improve:

1. **Check existing issues** - Avoid duplicates
2. **Create a new issue** with:
   - Clear title describing the problem
   - Step-by-step reproduction instructions
   - Expected vs actual behavior
   - Your environment (OS, bash version, etc.)
   - Any error messages or logs

### Suggest Features

Have an idea? We'd love to hear it:

1. **Start a Discussion** (preferred for features)
2. **Or create an Issue** with label `enhancement`
3. Include:
   - Clear description of the feature
   - Use cases and benefits
   - How it would work
   - Any examples or mockups

### Submit Code

Want to contribute code?

#### Before You Start
- Check open issues/PRs to avoid duplication
- Start a discussion for major changes
- Fork the repository

#### Making Changes

1. **Clone and setup:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/github-security-audit.git
   cd github-security-audit
   git checkout -b feature/description
   ```

2. **Make your changes:**
   - Follow the code style (see below)
   - Add comments for complex logic
   - Test thoroughly

3. **Test your code:**
   ```bash
   # Check syntax
   bash -n scripts/script.sh
   bash -n handlers/handler.sh

   # Test functionality
   ./scripts/audit_master.sh your-username test_reports
   ```

4. **Commit with clear messages:**
   ```bash
   git commit -m "Add feature: description of what you added"
   git push origin feature/description
   ```

5. **Create a Pull Request** with:
   - Description of changes
   - Link to related issue/discussion
   - Any testing notes

## 🎨 Code Style Guidelines

### Bash Style

- **Use bash 4.0+ features** (it's well-supported)
- **Always quote variables:** `"$var"` not `$var`
- **Use `[[ ]]` for conditionals** not `[ ]`
- **Include shebang:** `#!/usr/bin/env bash`
- **Include set options:** `set -euo pipefail`
- **Indent with 2 spaces** (not tabs)
- **Comment complex logic** but keep functions simple
- **Use meaningful variable names**

### Example Handler

```bash
#!/usr/bin/env bash
# Handler: Feature name
# Short description of what this audits

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Validate inputs
OWNER="${1:?Owner parameter required}"
OUTPUT_TYPE="${2:-csv}"

# Check prerequisites
if ! check_prerequisites; then
  exit 1
fi

log_info "Auditing [Feature] for $OWNER"

# Output header (if CSV)
if [[ "$OUTPUT_TYPE" == "csv" ]]; then
  echo "repo,field1,field2,field3"
fi

# Process repositories
TOTAL=0
COUNT_METRIC_1=0

REPOS=$(get_repos "$OWNER")

for row in $REPOS; do
  REPO_JSON=$(decode_repo_json "$row")
  REPO=$(echo "$REPO_JSON" | jq -r '.nameWithOwner')
  
  # Fetch data and audit
  # ... your logic here ...
  
  if [[ "$OUTPUT_TYPE" == "csv" ]]; then
    echo "$REPO,value1,value2,value3"
  fi
  
  TOTAL=$((TOTAL + 1))
  # Track metrics
done

# Output statistics to stderr for master script
cat >&2 <<EOF
{
  "handler": "handler_name",
  "total": $TOTAL,
  "metric1": $COUNT_METRIC_1
}
EOF
```

### Documentation Style

- **Use Markdown** for all documentation
- **Include code examples** where relevant
- **Use clear headings** with proper hierarchy
- **Add tables** for structured data
- **Include links** to related documentation
- **Reference user examples** with placeholders, not real usernames

## 🧪 Testing Requirements

Before submitting your contribution:

### Syntax Check
```bash
bash -n scripts/*.sh
bash -n handlers/*.sh
bash -n lib/*.sh
```

### Functional Testing
```bash
# Test with your GitHub account
./scripts/audit_master.sh your-username test_reports

# Verify reports generated
ls -la test_reports/

# Check individual handlers
./handlers/your_handler.sh your-username
```

### Documentation Testing
- [ ] README is accurate
- [ ] Installation instructions work
- [ ] Usage examples are correct
- [ ] Code snippets execute without errors

## 📝 Creating a Custom Handler

Add a new security audit handler:

1. **Copy template:**
   ```bash
   cp handlers/secret_scanning.sh handlers/my_new_handler.sh
   ```

2. **Modify to audit your feature:**
   - Change handler name
   - Update audit logic
   - Adjust metrics
   - Test with your data

3. **Test thoroughly:**
   ```bash
   bash -n handlers/my_new_handler.sh
   ./handlers/my_new_handler.sh your-username
   ```

4. **Add to master script:**
   Edit `scripts/audit_master.sh`:
   ```bash
   HANDLERS=(
     "secret_scanning"
     "dependabot"
     "branch_protection"
     "code_scanning"
     "repo_config"
     "my_new_handler"        # Add here
   )
   ```

5. **Document:**
   - Add to [Handler Documentation](wiki/Handler-Development.md)
   - Include in [Architecture](ARCHITECTURE.md)
   - Update [Wiki](wiki/Home.md)

6. **Submit PR** with:
   - New handler code
   - Updated documentation
   - Usage examples
   - Testing notes

## 📚 Documentation Contributions

Want to improve documentation?

1. **Small fixes** - Create PR directly
2. **Major changes** - Start a discussion first
3. **New guides** - Follow existing format
4. **Examples** - Use realistic scenarios

### Documentation Files

- `README.md` - Project overview
- `wiki/*.md` - Comprehensive guides
- `ARCHITECTURE.md` - System design
- `QUICKSTART.md` - Quick start guide
- Code comments - Inline documentation

## ✅ Pull Request Checklist

Before submitting your PR:

- [ ] Code follows style guidelines
- [ ] Syntax check passes: `bash -n`
- [ ] Tested with real data
- [ ] Documentation updated
- [ ] No hardcoded credentials/paths
- [ ] Commit messages are clear
- [ ] Related issues/discussions referenced
- [ ] License header present (if new file)
- [ ] CHANGELOG updated (if applicable)

## 🐛 Reporting Security Issues

**Do NOT create a public issue for security vulnerabilities!**

Instead:
1. Email maintainers at: [security@example.com]
2. Include: description, steps to reproduce, potential impact
3. We'll acknowledge within 24 hours
4. We'll work on fix and coordinated disclosure

See [SECURITY.md](SECURITY.md) for details.

## 📖 Code Review Process

All contributions go through review:

1. **Automated checks** - Syntax and tests
2. **Code review** - Maintainers review code
3. **Feedback** - Suggestions for improvement
4. **Revisions** - Update based on feedback
5. **Approval** - Merges when ready

*This may take a few days. Thank you for your patience!*

## 🎓 Development Workflow

```
1. Fork repository
   └─→ Create your copy on GitHub

2. Clone locally
   └─→ git clone your-fork && cd github-security-audit

3. Create branch
   └─→ git checkout -b feature/your-feature

4. Make changes
   └─→ Edit files, test, commit

5. Push to fork
   └─→ git push origin feature/your-feature

6. Create Pull Request
   └─→ Compare and create PR on GitHub

7. Address feedback
   └─→ Update code based on review

8. Merge
   └─→ Maintainers merge to main
```

## 📝 Commit Message Guidelines

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add custom handler for license scanning"
git commit -m "Fix rate limit handling in dependabot handler"
git commit -m "Update installation guide for Linux"

# Avoid
git commit -m "Fix bug"
git commit -m "Update stuff"
git commit -m "WIP"
```

## 🚀 Release Process

For maintainers:

1. Create release branch: `git checkout -b release/vX.Y.Z`
2. Update version numbers
3. Update CHANGELOG
4. Create PR and merge
5. Create tagged release on GitHub
6. Publish to package managers (if applicable)

## 📞 Getting Help

- **Questions?** Start a [Discussion](https://github.com/YOUR_USERNAME/github-security-audit/discussions)
- **Need guidance?** Comment on your issue/PR
- **Want to chat?** Email maintainers

## 🙏 Thank You!

Contributing takes time and effort. We appreciate every contribution, whether it's:
- Bug reports
- Feature suggestions
- Code improvements
- Documentation enhancements
- Testing and feedback
- Sharing the project with others

Together we're building a better security tool for GitHub!

---

**Last Updated:** March 4, 2026

Happy contributing! 🎉
