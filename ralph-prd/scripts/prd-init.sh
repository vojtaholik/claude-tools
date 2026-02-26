#!/usr/bin/env bash
# Scaffold a prd.json file from arguments.
# Usage: prd-init.sh <project_name> <json_stories>
# json_stories is a JSON array string of story objects
set -euo pipefail

PROJECT="${1:?Usage: prd-init.sh <project_name> <json_stories>}"
STORIES="${2:?Stories JSON array required}"

if [[ -f "prd.json" ]]; then
  echo "⚠️ prd.json already exists. Use prd-next.sh to check status."
  exit 1
fi

# Validate JSON
echo "$STORIES" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null || {
  echo "Error: Invalid JSON for stories" >&2
  exit 1
}

python3 -c "
import json, sys

project = sys.argv[1]
stories = json.loads(sys.argv[2])

# Ensure required fields
for i, s in enumerate(stories):
    s.setdefault('id', f'{project[:4]}-{i+1:02d}')
    s.setdefault('status', 'pending')
    s.setdefault('priority', i + 1)
    s.setdefault('skills', [])

prd = {
    'project': project,
    'stories': stories
}

with open('prd.json', 'w') as f:
    json.dump(prd, f, indent=2)

print('Created prd.json with %d stories' % len(stories))
for s in stories:
    icon = 'done' if s['status'] == 'done' else 'pending'
    print('  [%s] %s  %s  (priority %s)' % (icon, s['id'], s['title'], s['priority']))
" "$PROJECT" "$STORIES"
