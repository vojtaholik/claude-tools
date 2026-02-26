#!/usr/bin/env bash
# Mark a story as done in prd.json.
# Usage: prd-mark.sh <story_id> [path/to/prd.json]
set -euo pipefail

STORY_ID="${1:?Usage: prd-mark.sh <story_id> [prd.json]}"
PRD_FILE="${2:-prd.json}"

if [[ ! -f "$PRD_FILE" ]]; then
  echo "No prd.json found" >&2
  exit 1
fi

python3 -c "
import json, sys
from datetime import datetime, timezone

story_id = sys.argv[1]
prd_file = sys.argv[2]

with open(prd_file) as f:
    prd = json.load(f)

found = False
for s in prd['stories']:
    if s['id'] == story_id:
        s['status'] = 'done'
        s['completedAt'] = datetime.now(timezone.utc).isoformat()
        found = True
        break

if not found:
    print(f'Story {story_id} not found', file=sys.stderr)
    sys.exit(1)

with open(prd_file, 'w') as f:
    json.dump(prd, f, indent=2)

done = sum(1 for s in prd['stories'] if s['status'] == 'done')
total = len(prd['stories'])
print(f'Marked {story_id} done ({done}/{total})')
" "$STORY_ID" "$PRD_FILE"
