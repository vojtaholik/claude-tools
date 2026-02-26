#!/usr/bin/env bash
# Quick repo stats: language breakdown, file counts, largest files, recent churn.
# Usage: repo-stats.sh [path]
set -euo pipefail

DIR="${1:-.}"
cd "$DIR"

echo "## File Counts by Extension"
find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './.next/*' -not -path './dist/*' -not -path './build/*' -not -path './.turbo/*' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20

echo ""
echo "## Largest Files (top 15)"
find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './.next/*' -not -path './dist/*' -not -path './build/*' -not -path './.turbo/*' | xargs ls -la 2>/dev/null | sort -k5 -rn | head -15 | awk '{print $5, $NF}'

echo ""
echo "## Most Changed Files (last 100 commits)"
if git rev-parse --git-dir > /dev/null 2>&1; then
  git log --pretty=format: --name-only -100 2>/dev/null | sort | uniq -c | sort -rn | head -15
else
  echo "(not a git repo)"
fi

echo ""
echo "## TODO/FIXME/HACK Count"
grep -r --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.py' --include='*.go' --include='*.rs' -c 'TODO\|FIXME\|HACK\|XXX' . 2>/dev/null | grep -v ':0$' | sort -t: -k2 -rn | head -10 || echo "(none found)"
