#!/usr/bin/env bash
# ============================================================
# Script Name : upload_wiki.sh
# Purpose     : Upload wiki pages to GitHub repository wiki
# Usage       : ./upload_wiki.sh
# Requirements: Git, GitHub CLI (gh)
# ============================================================

set -euo pipefail

REPO="nsoni44/github-security-audit"
WIKI_DIR="wiki"
TMP_DIR="/tmp/wiki-upload-$$"

echo "========================================"
echo "GitHub Wiki Upload Script"
echo "========================================"
echo ""

# Check if wiki files exist
if [[ ! -d "$WIKI_DIR" ]]; then
  echo "❌ Error: Wiki directory not found"
  exit 1
fi

# Check if there are wiki files
if [[ ! -f "$WIKI_DIR/Home.md" ]]; then
  echo "❌ Error: Home.md not found in wiki directory"
  exit 1
fi

echo "📁 Found wiki directory with files:"
ls -1 "$WIKI_DIR"/*.md | xargs -n1 basename
echo ""

# Create temporary directory
echo "📂 Creating temporary directory..."
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# Initialize git
echo "🔧 Initializing git repository..."
git init -q

# Try to clone existing wiki (if it exists)
echo "🔄 Checking if wiki repository exists..."
if git clone "https://github.com/$REPO.wiki.git" existing-wiki 2>/dev/null; then
  echo "✓ Wiki exists, copying existing content..."
  cp -r existing-wiki/.git ./.git
  rm -rf existing-wiki
else
  echo "⚠️  Wiki repository not initialized yet"
  echo ""
  echo "┌─────────────────────────────────────────────────────────────┐"
  echo "│ ACTION REQUIRED: Create Initial Wiki Page                  │"
  echo "└─────────────────────────────────────────────────────────────┘"
  echo ""
  echo "GitHub requires at least one page to be created via the web"
  echo "interface before the wiki git repository is initialized."
  echo ""
  echo "Steps:"
  echo "  1. Open: https://github.com/$REPO/wiki/_new"
  echo "  2. Create any page (e.g., 'Home' with 'Initial setup')"
  echo "  3. Click 'Save Page'"
  echo "  4. Run this script again"
  echo ""
  read -p "Press Enter to open the browser, or Ctrl+C to exit..."
  
  # Try to open browser
  if command -v open >/dev/null 2>&1; then
    open "https://github.com/$REPO/wiki/_new"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "https://github.com/$REPO/wiki/_new"
  else
    echo "Please manually open: https://github.com/$REPO/wiki/_new"
  fi
  
  echo ""
  echo "After creating the initial page, run this script again."
  rm -rf "$TMP_DIR"
  exit 0
fi

# Copy wiki files
echo "📝 Copying wiki files..."
cp "$OLDPWD/$WIKI_DIR"/*.md .

# Add and commit
echo "💾 Committing changes..."
git add .
git commit -m "Update wiki pages

- Home page with project overview
- Installation guide
- Usage guide with examples
- Improvements guide
- FAQ
- Security and publishing guide
" || echo "ℹ️  No changes to commit"

# Push to wiki
echo "📤 Pushing to GitHub wiki..."
git push "https://github.com/$REPO.wiki.git" main:master --force

echo ""
echo "========================================"
echo "✅ Wiki upload complete!"
echo "========================================"
echo ""
echo "View wiki at: https://github.com/$REPO/wiki"
echo ""

# Cleanup
cd "$OLDPWD"
rm -rf "$TMP_DIR"
