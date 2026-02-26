#!/usr/bin/env bash
# One-time git init + commit script. Run this, then delete it.
set -euo pipefail

cd "$(dirname "$0")"

# Make all scripts executable
find . -name "*.sh" -exec chmod +x {} \;

# Git init + commit
git init
git add .
git commit -m "feat: claude-tools v1 — ralph recipes, PRD loops, skill injection, repo autopsy, session lifecycle"

echo ""
echo "Done. You can delete this script:"
echo "  rm init-git.sh"
