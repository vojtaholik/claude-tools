#!/usr/bin/env bash
# Output the next pending story from prd.json as JSON.
# Usage: prd-next.sh [path/to/prd.json]
# Exit 0 + JSON if found, exit 1 if all done or no file.
set -euo pipefail

PRD_FILE="${1:-prd.json}"

if [[ ! -f "$PRD_FILE" ]]; then
  echo "No prd.json found" >&2
  exit 1
fi

python3 -c "
import json, sys

with open(sys.argv[1]) as f:
    prd = json.load(f)

pending = [s for s in prd['stories'] if s.get('status') != 'done']
pending.sort(key=lambda s: s.get('priority', 999))

if not pending:
    print('ALL_STORIES_DONE')
    sys.exit(1)

# Print status table to stderr
total = len(prd['stories'])
done = total - len(pending)
print('%s -- %d/%d stories done' % (prd['project'], done, total), file=sys.stderr)
for s in prd['stories']:
    icon = '[done]' if s['status'] == 'done' else '[next]' if s == pending[0] else '[    ]'
    print('  %s %s  %s' % (icon, s['id'], s['title']), file=sys.stderr)
print(file=sys.stderr)

# Print next story as JSON to stdout
print(json.dumps(pending[0]))
" "$PRD_FILE"
