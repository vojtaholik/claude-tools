# claude-tools Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a modular toolkit of 5 tools for Claude Code — ralph loop recipes, PRD-driven loops, skill injection, repo autopsy, and session lifecycle.

**Architecture:** Claude Code plugin using skills (markdown commands), hooks (shell scripts on session events), and CLI scripts (bash for heavy lifting). Installed via symlinks into `~/.claude/`.

**Tech Stack:** Bash scripts, YAML/JSON state files, Claude Code plugin system (`.claude-plugin/plugin.json`, `commands/`, `hooks/`)

---

### Task 1: Scaffold project structure + plugin manifest

**Files:**
- Create: `README.md`
- Create: `.claude-plugin/plugin.json`
- Create: `shared/utils.sh`

**Step 1: Create plugin manifest**

```json
{
  "name": "claude-tools",
  "description": "Pi-tools lite for Claude Code. Ralph loop recipes, PRD-driven loops, skill injection, repo autopsy, session lifecycle.",
  "author": { "name": "Vojta Holik" }
}
```

**Step 2: Create shared utils**

`shared/utils.sh` — common helpers used by all scripts:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse YAML frontmatter from a state file
# Usage: parse_frontmatter "key" "file"
parse_frontmatter() {
  local key="$1" file="$2"
  sed -n '/^---$/,/^---$/p' "$file" | grep "^${key}:" | sed "s/^${key}: *//" | sed 's/^"//' | sed 's/"$//'
}

# Update a frontmatter field in place
# Usage: update_frontmatter "key" "value" "file"
update_frontmatter() {
  local key="$1" value="$2" file="$3"
  local tmp="${file}.tmp"
  sed "s/^${key}:.*/${key}: ${value}/" "$file" > "$tmp" && mv "$tmp" "$file"
}

# Extract prompt text (everything after second ---)
# Usage: extract_prompt "file"
extract_prompt() {
  awk '/^---$/{i++; next} i>=2' "$1"
}

# Resolve skill SKILL.md paths
# Usage: resolve_skill "skill-name"
# Returns path to SKILL.md or empty string
resolve_skill() {
  local name="$1"
  local search_paths=(
    "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers/"*/skills/"$name"
    "$HOME/.claude/plugins/marketplaces/"*/plugins/*/skills/"$name"
    "$HOME/.claude/plugins/"*/skills/"$name"
    "./.claude/skills/$name"
  )
  for pattern in "${search_paths[@]}"; do
    for dir in $pattern; do
      if [[ -f "$dir/SKILL.md" ]]; then
        echo "$dir/SKILL.md"
        return 0
      fi
    done
  done
  # Try matching by partial name (e.g. "test-driven-development" inside "superpowers")
  local found
  found=$(find "$HOME/.claude/plugins" -path "*/$name/SKILL.md" -type f 2>/dev/null | head -1)
  if [[ -n "$found" ]]; then
    echo "$found"
    return 0
  fi
  return 1
}

# Read skill content with header
# Usage: read_skill "skill-name"
read_skill() {
  local name="$1"
  local path
  if path=$(resolve_skill "$name"); then
    echo "# Skill: $name"
    echo ""
    cat "$path"
  else
    echo "# Skill: $name (NOT FOUND)"
    return 1
  fi
}

# JSON escape a string for hook output
json_escape() {
  python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))" <<< "$1"
}
```

**Step 3: Create README.md**

Minimal README with tool list, install instructions, usage examples.

**Step 4: Commit**

```bash
git init
git add .
git commit -m "feat: scaffold claude-tools project with plugin manifest and shared utils"
```

---

### Task 2: Skill injection system

**Files:**
- Create: `skill-inject/scripts/inject-skills.sh`

Build this before recipes since recipes depend on it.

**Step 1: Write inject-skills.sh**

```bash
#!/usr/bin/env bash
# Reads skill names (comma-separated), resolves SKILL.md files,
# outputs combined content suitable for prepending to a prompt.
#
# Usage: inject-skills.sh "skill1,skill2,skill3"
# Output: Combined skill content to stdout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../shared/utils.sh"

SKILLS_ARG="${1:-}"
MAX_SKILLS=3
MAX_WORDS=4000

if [[ -z "$SKILLS_ARG" ]]; then
  exit 0
fi

IFS=',' read -ra SKILL_NAMES <<< "$SKILLS_ARG"

if (( ${#SKILL_NAMES[@]} > MAX_SKILLS )); then
  echo "⚠️ Warning: Max $MAX_SKILLS skills per iteration. Using first $MAX_SKILLS." >&2
  SKILL_NAMES=("${SKILL_NAMES[@]:0:$MAX_SKILLS}")
fi

OUTPUT="## Injected Skills\n\nFollow these skill guidelines for all work in this iteration:\n\n"
TOTAL_WORDS=0

for name in "${SKILL_NAMES[@]}"; do
  name=$(echo "$name" | xargs) # trim whitespace
  CONTENT=$(read_skill "$name" 2>/dev/null || echo "")
  if [[ -z "$CONTENT" ]]; then
    echo "⚠️ Warning: Skill '$name' not found, skipping." >&2
    continue
  fi
  WORD_COUNT=$(echo "$CONTENT" | wc -w | xargs)
  TOTAL_WORDS=$((TOTAL_WORDS + WORD_COUNT))
  if (( TOTAL_WORDS > MAX_WORDS )); then
    echo "⚠️ Warning: Skill content exceeds ${MAX_WORDS} words, truncating '$name'." >&2
    REMAINING=$((MAX_WORDS - (TOTAL_WORDS - WORD_COUNT)))
    CONTENT=$(echo "$CONTENT" | head -c $((REMAINING * 6)))
    CONTENT="${CONTENT}\n\n[... truncated, ${MAX_WORDS} word limit reached]"
    OUTPUT="${OUTPUT}${CONTENT}\n\n---\n\n"
    break
  fi
  OUTPUT="${OUTPUT}${CONTENT}\n\n---\n\n"
done

echo -e "$OUTPUT"
```

**Step 2: Test manually**

```bash
chmod +x skill-inject/scripts/inject-skills.sh
./skill-inject/scripts/inject-skills.sh "test-driven-development"
```

Expected: Prints the TDD skill content with header.

**Step 3: Commit**

```bash
git add skill-inject/
git commit -m "feat: add skill injection system — resolves and combines SKILL.md files"
```

---

### Task 3: Ralph recipes — shared setup script

**Files:**
- Create: `ralph-recipes/scripts/start-recipe.sh`
- Create: `ralph-recipes/scripts/recipe-config.sh`

**Step 1: Write recipe-config.sh**

Defines the preset configurations for each recipe type:

```bash
#!/usr/bin/env bash
# Returns recipe configuration as shell variables
# Usage: source recipe-config.sh; get_recipe "tdd"
# Sets: RECIPE_MAX_ITERATIONS, RECIPE_COMPLETION_PROMISE, RECIPE_SKILLS, RECIPE_PROMPT_TEMPLATE

get_recipe() {
  local recipe="$1"
  case "$recipe" in
    tdd)
      RECIPE_MAX_ITERATIONS=15
      RECIPE_COMPLETION_PROMISE="ALL TESTS PASS"
      RECIPE_SKILLS="test-driven-development"
      RECIPE_PROMPT_TEMPLATE='You are in a TDD ralph loop. For the target described below:

1. Write a failing test for the next untested behavior
2. Run the test suite to confirm it fails
3. Write the MINIMAL implementation to make it pass
4. Run the test suite to confirm it passes
5. Refactor if needed (tests must stay green)
6. Repeat until fully tested

When ALL tests pass and coverage is complete, output: <promise>ALL TESTS PASS</promise>

Only output the promise when it is genuinely true. Do not lie to escape the loop.

TARGET: %TARGET%
SCOPE: %SCOPE%'
      ;;
    refactor)
      RECIPE_MAX_ITERATIONS=20
      RECIPE_COMPLETION_PROMISE="REFACTOR COMPLETE"
      RECIPE_SKILLS=""
      RECIPE_PROMPT_TEMPLATE='You are in a refactoring ralph loop. For the target described below:

1. Run the full test suite first — all tests MUST pass before any changes
2. Make ONE focused refactoring improvement
3. Run the test suite — all tests MUST still pass
4. Run typecheck — MUST have no type errors
5. Repeat

Refactoring priorities: extract duplication, simplify conditionals, improve naming, reduce coupling.
Do NOT add features. Do NOT change behavior. Tests are your safety net.

When the code is clean and no more improvements are obvious, output: <promise>REFACTOR COMPLETE</promise>

Only output the promise when it is genuinely true.

TARGET: %TARGET%
SCOPE: %SCOPE%'
      ;;
    greenfield)
      RECIPE_MAX_ITERATIONS=30
      RECIPE_COMPLETION_PROMISE=""  # user-defined
      RECIPE_SKILLS=""
      RECIPE_PROMPT_TEMPLATE='You are in a greenfield ralph loop building something from scratch.

1. Scaffold the project structure if not already done
2. Write a failing test for the next piece of functionality
3. Implement it
4. Run tests to confirm
5. Commit working increments
6. Repeat

WHAT TO BUILD: %TARGET%
CONSTRAINTS: %SCOPE%
DONE WHEN: %DONE_CRITERIA%

When the done criteria are fully met, output: <promise>%COMPLETION_PROMISE%</promise>

Only output the promise when it is genuinely true.'
      ;;
    review)
      RECIPE_MAX_ITERATIONS=10
      RECIPE_COMPLETION_PROMISE="ALL CLEAN"
      RECIPE_SKILLS=""
      RECIPE_PROMPT_TEMPLATE='You are in a code review ralph loop. Run two passes:

PASS 1 — VALIDATOR:
Check for: correctness bugs, logic errors, missing edge cases, security issues, type errors, broken patterns.
Fix any issues found.

PASS 2 — MINIFIER:
Check for: unnecessary complexity, dead code, over-abstraction, verbose patterns that could be simpler.
Simplify where possible without changing behavior.

Run the test suite after each change. Tests MUST pass.

When both passes find zero issues, output: <promise>ALL CLEAN</promise>

Only output the promise when it is genuinely true.

TARGET: %TARGET%
SCOPE: %SCOPE%'
      ;;
    *)
      echo "Unknown recipe: $recipe" >&2
      return 1
      ;;
  esac
}
```

**Step 2: Write start-recipe.sh**

```bash
#!/usr/bin/env bash
# Starts a ralph loop with a recipe configuration.
# Called by recipe skill commands.
#
# Usage: start-recipe.sh <recipe> <target> [scope] [done_criteria] [completion_promise]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/recipe-config.sh"
source "$SCRIPT_DIR/../../shared/utils.sh"

RECIPE="${1:?Usage: start-recipe.sh <recipe> <target> [scope] [done_criteria] [completion_promise]}"
TARGET="${2:?Target is required}"
SCOPE="${3:-No specific constraints}"
DONE_CRITERIA="${4:-}"
CUSTOM_PROMISE="${5:-}"

get_recipe "$RECIPE"

# Apply overrides for greenfield
if [[ "$RECIPE" = "greenfield" ]]; then
  if [[ -z "$DONE_CRITERIA" ]]; then
    echo "Error: greenfield recipe requires done criteria" >&2
    exit 1
  fi
  if [[ -z "$CUSTOM_PROMISE" ]]; then
    CUSTOM_PROMISE="$DONE_CRITERIA"
  fi
  RECIPE_COMPLETION_PROMISE="$CUSTOM_PROMISE"
fi

# Build prompt from template
PROMPT="${RECIPE_PROMPT_TEMPLATE}"
PROMPT="${PROMPT//%TARGET%/$TARGET}"
PROMPT="${PROMPT//%SCOPE%/$SCOPE}"
PROMPT="${PROMPT//%DONE_CRITERIA%/$DONE_CRITERIA}"
PROMPT="${PROMPT//%COMPLETION_PROMISE%/$RECIPE_COMPLETION_PROMISE}"

# Inject skills if specified
if [[ -n "$RECIPE_SKILLS" ]]; then
  SKILL_CONTENT=$("$SCRIPT_DIR/../../skill-inject/scripts/inject-skills.sh" "$RECIPE_SKILLS" 2>/dev/null || echo "")
  if [[ -n "$SKILL_CONTENT" ]]; then
    PROMPT="${SKILL_CONTENT}

---

${PROMPT}"
  fi
fi

# Create ralph loop state file
mkdir -p .claude
cat > .claude/ralph-loop.local.md <<EOF
---
active: true
iteration: 1
max_iterations: $RECIPE_MAX_ITERATIONS
completion_promise: "$RECIPE_COMPLETION_PROMISE"
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
recipe: "$RECIPE"
skills: "$RECIPE_SKILLS"
---

$PROMPT
EOF

echo "🔄 Ralph $RECIPE loop started"
echo "   Target: $TARGET"
echo "   Max iterations: $RECIPE_MAX_ITERATIONS"
echo "   Completion: <promise>$RECIPE_COMPLETION_PROMISE</promise>"
if [[ -n "$RECIPE_SKILLS" ]]; then
  echo "   Skills: $RECIPE_SKILLS"
fi
echo ""
echo "The loop will re-feed your prompt on each exit attempt."
echo "To cancel: /cancel-ralph"
```

**Step 3: Commit**

```bash
git add ralph-recipes/
git commit -m "feat: add ralph recipe configs and start script — tdd, refactor, greenfield, review"
```

---

### Task 4: Ralph recipe skill commands

**Files:**
- Create: `ralph-recipes/commands/ralph-tdd.md`
- Create: `ralph-recipes/commands/ralph-refactor.md`
- Create: `ralph-recipes/commands/ralph-greenfield.md`
- Create: `ralph-recipes/commands/ralph-review.md`

**Step 1: Write ralph-tdd.md**

```markdown
---
description: "Start a TDD ralph loop"
argument-hint: ""
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh:*)"]
---

# Ralph TDD Loop

Start a test-driven development ralph loop.

Ask the user these questions ONE AT A TIME:

1. **Target** — "What file, module, or feature should I write tests for?"
2. **Scope** — "Any constraints? (e.g. skip integration tests, focus on edge cases, specific test framework)"

Then run:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-recipes/scripts/start-recipe.sh tdd "<target>" "<scope>"
```

After the script runs, tell the user the loop is active and begin working on the first test.
```

**Step 2: Write ralph-refactor.md**

Same pattern — asks for target + scope, calls `start-recipe.sh refactor`.

**Step 3: Write ralph-greenfield.md**

Asks for target + scope + done criteria, calls `start-recipe.sh greenfield`.

**Step 4: Write ralph-review.md**

Asks for target + scope, calls `start-recipe.sh review`.

**Step 5: Commit**

```bash
git add ralph-recipes/commands/
git commit -m "feat: add recipe skill commands — /ralph-tdd, /ralph-refactor, /ralph-greenfield, /ralph-review"
```

---

### Task 5: PRD scripts

**Files:**
- Create: `ralph-prd/scripts/prd-init.sh`
- Create: `ralph-prd/scripts/prd-next.sh`
- Create: `ralph-prd/scripts/prd-mark.sh`

**Step 1: Write prd-init.sh**

```bash
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

print(f'✅ Created prd.json with {len(stories)} stories')
for s in stories:
    icon = '✓' if s['status'] == 'done' else '○'
    print(f\"  {icon} {s['id']}  {s['title']}  (priority {s['priority']})\")
" "$PROJECT" "$STORIES"
```

**Step 2: Write prd-next.sh**

```bash
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
print(f\"📋 {prd['project']} — {done}/{total} stories done\", file=sys.stderr)
for s in prd['stories']:
    icon = '✓' if s['status'] == 'done' else '▸' if s == pending[0] else '○'
    print(f\"  {icon} {s['id']}  {s['title']}\", file=sys.stderr)
print(file=sys.stderr)

# Print next story as JSON to stdout
print(json.dumps(pending[0]))
" "$PRD_FILE"
```

**Step 3: Write prd-mark.sh**

```bash
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
print(f'✅ Marked {story_id} done ({done}/{total})')
" "$STORY_ID" "$PRD_FILE"
```

**Step 4: Test scripts**

```bash
chmod +x ralph-prd/scripts/*.sh
./ralph-prd/scripts/prd-init.sh "test-project" '[{"title":"First story","prompt":"Do thing 1"},{"title":"Second story","prompt":"Do thing 2"}]'
./ralph-prd/scripts/prd-next.sh
./ralph-prd/scripts/prd-mark.sh "test-01"
./ralph-prd/scripts/prd-next.sh
cat prd.json
rm prd.json
```

**Step 5: Commit**

```bash
git add ralph-prd/scripts/
git commit -m "feat: add PRD scripts — init, next story, mark done"
```

---

### Task 6: PRD stop hook

**Files:**
- Create: `ralph-prd/hooks/stop-hook-prd.sh`

This is the modified stop hook that reads `prd.json` instead of repeating one prompt.

**Step 1: Write stop-hook-prd.sh**

```bash
#!/usr/bin/env bash
# PRD-aware stop hook for ralph loops.
# When a ralph-prd loop is active:
#   - Checks if current story's promise was met
#   - If yes: marks story done, picks next story
#   - If all stories done: exits loop
#   - If no: re-feeds same story prompt
#
# Falls through to normal ralph stop hook behavior for non-PRD loops.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../shared/utils.sh"

RALPH_STATE=".claude/ralph-loop.local.md"

# No active loop — don't block
if [[ ! -f "$RALPH_STATE" ]]; then
  exit 0
fi

RECIPE=$(parse_frontmatter "recipe" "$RALPH_STATE" 2>/dev/null || echo "")

# Not a PRD loop — let the standard stop hook handle it
if [[ "$RECIPE" != "prd" ]]; then
  exit 0
fi

# Read stdin (Claude Code passes JSON with transcript_path)
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || echo "")

# Extract last assistant message
LAST_OUTPUT=""
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1 | python3 -c "
import json,sys
msg = json.load(sys.stdin)
parts = msg.get('message',{}).get('content',[])
print('\n'.join(p.get('text','') for p in parts if p.get('type')=='text'))
" 2>/dev/null || echo "")
fi

ITERATION=$(parse_frontmatter "iteration" "$RALPH_STATE")
MAX_ITERATIONS=$(parse_frontmatter "max_iterations" "$RALPH_STATE")
SKILLS=$(parse_frontmatter "skills" "$RALPH_STATE" 2>/dev/null || echo "")

# Check max iterations
if [[ -n "$MAX_ITERATIONS" ]] && [[ "$MAX_ITERATIONS" != "0" ]] && (( ITERATION >= MAX_ITERATIONS )); then
  echo "⏹️ Ralph PRD loop: max iterations ($MAX_ITERATIONS) reached" >&2
  rm "$RALPH_STATE"
  exit 0
fi

# Get current story
NEXT_STORY=$("$SCRIPT_DIR/../scripts/prd-next.sh" 2>/dev/null || echo "ALL_STORIES_DONE")

if [[ "$NEXT_STORY" = "ALL_STORIES_DONE" ]]; then
  echo "✅ Ralph PRD loop: all stories complete!" >&2
  rm "$RALPH_STATE"
  exit 0
fi

STORY_ID=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
STORY_TITLE=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])" 2>/dev/null || echo "")
STORY_PROMPT=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])" 2>/dev/null || echo "")
STORY_SKILLS=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(','.join(json.load(sys.stdin).get('skills',[])))" 2>/dev/null || echo "")

# Check if last output signals story completion
# Convention: story is done when tests pass and agent says so
PROMISE_TEXT=""
if [[ -n "$LAST_OUTPUT" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
fi

if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "STORY DONE" ]]; then
  # Mark current story done, get next
  "$SCRIPT_DIR/../scripts/prd-mark.sh" "$STORY_ID" 2>/dev/null
  NEXT_STORY=$("$SCRIPT_DIR/../scripts/prd-next.sh" 2>/dev/null || echo "ALL_STORIES_DONE")

  if [[ "$NEXT_STORY" = "ALL_STORIES_DONE" ]]; then
    echo "✅ Ralph PRD loop: all stories complete!" >&2
    rm "$RALPH_STATE"
    exit 0
  fi

  STORY_ID=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
  STORY_TITLE=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['title'])" 2>/dev/null || echo "")
  STORY_PROMPT=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(json.load(sys.stdin)['prompt'])" 2>/dev/null || echo "")
  STORY_SKILLS=$(echo "$NEXT_STORY" | python3 -c "import json,sys; print(','.join(json.load(sys.stdin).get('skills',[])))" 2>/dev/null || echo "")
fi

# Increment iteration
NEW_ITERATION=$((ITERATION + 1))
update_frontmatter "iteration" "$NEW_ITERATION" "$RALPH_STATE"

# Build prompt with skill injection
PROMPT=""
ALL_SKILLS="${SKILLS}"
if [[ -n "$STORY_SKILLS" ]]; then
  if [[ -n "$ALL_SKILLS" ]]; then
    ALL_SKILLS="${ALL_SKILLS},${STORY_SKILLS}"
  else
    ALL_SKILLS="$STORY_SKILLS"
  fi
fi

if [[ -n "$ALL_SKILLS" ]]; then
  SKILL_CONTENT=$("$SCRIPT_DIR/../../skill-inject/scripts/inject-skills.sh" "$ALL_SKILLS" 2>/dev/null || echo "")
  if [[ -n "$SKILL_CONTENT" ]]; then
    PROMPT="${SKILL_CONTENT}\n\n---\n\n"
  fi
fi

PROMPT="${PROMPT}# Story: ${STORY_TITLE} (${STORY_ID})

${STORY_PROMPT}

When this story is fully implemented and tests pass, output: <promise>STORY DONE</promise>
Only output the promise when it is genuinely true."

# Block the stop and re-feed
ESCAPED_PROMPT=$(echo -e "$PROMPT" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")

cat <<HOOKJSON
{
  "decision": "block",
  "reason": ${ESCAPED_PROMPT},
  "systemMessage": "🔄 Ralph PRD iteration ${NEW_ITERATION}/${MAX_ITERATIONS} | Story: ${STORY_TITLE} | To stop: /cancel-ralph"
}
HOOKJSON
```

**Step 2: Commit**

```bash
git add ralph-prd/hooks/
git commit -m "feat: add PRD-aware stop hook — picks stories, marks done, injects skills"
```

---

### Task 7: PRD skill command

**Files:**
- Create: `ralph-prd/commands/ralph-prd.md`

**Step 1: Write ralph-prd.md**

```markdown
---
description: "Start a PRD-driven ralph loop"
argument-hint: "[init]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/ralph-prd/scripts/*:*)", "Read", "Write"]
---

# Ralph PRD Loop

Start an autonomous ralph loop that works through stories in prd.json.

## If argument is "init" or no prd.json exists:

Scaffold a new PRD interactively. Ask the user ONE AT A TIME:

1. **Project name** — "What's the project called?"
2. **Stories** — "Describe the first story (what needs to be built)."
   - After each story: "Add another story? (describe it, or say 'done')"
   - For each story, generate: id, title, prompt, priority, skills (suggest relevant ones)

Then run prd-init.sh with the collected data:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-prd/scripts/prd-init.sh "<project>" '<stories_json>'
```

Ask: "Start the loop now?"

## If prd.json exists:

Show current status by running:

```bash
${CLAUDE_PLUGIN_ROOT}/ralph-prd/scripts/prd-next.sh
```

Then create the ralph loop state file for PRD mode:

```bash
mkdir -p .claude
cat > .claude/ralph-loop.local.md <<'STATE'
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "STORY DONE"
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
recipe: "prd"
skills: ""
---

PRD-driven loop. Stories managed by prd.json.
STATE
```

Then begin working on the first pending story immediately.
```

**Step 2: Commit**

```bash
git add ralph-prd/commands/
git commit -m "feat: add /ralph-prd skill command — scaffold or start PRD loops"
```

---

### Task 8: Repo autopsy skill

**Files:**
- Create: `repo-autopsy/commands/autopsy.md`
- Create: `repo-autopsy/scripts/repo-stats.sh`

**Step 1: Write repo-stats.sh**

```bash
#!/usr/bin/env bash
# Quick repo stats: language breakdown, file counts, largest files, recent churn.
# Usage: repo-stats.sh [path]
set -euo pipefail

DIR="${1:-.}"
cd "$DIR"

echo "## File Counts by Extension"
find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './.next/*' -not -path './dist/*' -not -path './build/*' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20

echo ""
echo "## Largest Files (top 15)"
find . -type f -not -path './.git/*' -not -path './node_modules/*' -not -path './.next/*' -not -path './dist/*' -not -path './build/*' | xargs ls -la 2>/dev/null | sort -k5 -rn | head -15 | awk '{print $5, $NF}'

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
```

**Step 2: Write autopsy.md**

```markdown
---
description: "Run structured codebase analysis"
argument-hint: "[path or URL]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/repo-autopsy/scripts/repo-stats.sh:*)", "Glob", "Grep", "Read", "Bash"]
---

# Repo Autopsy

Run a 5-pass structured analysis on a codebase. If given a URL, clone it first.

## Pass 1: Structure
- Use Glob to map the directory tree (depth 3)
- Run repo-stats.sh for language breakdown
- Identify entry points (main files, index files, app files)
- List config files (tsconfig, package.json, Dockerfile, etc.)

## Pass 2: Dependencies
- Read package.json / go.mod / Cargo.toml / requirements.txt
- Use Grep to find the most-imported internal files (top 10 by import count)
- Count external dependencies (prod vs dev)
- Check for circular dependencies (A imports B imports A)

## Pass 3: Hotspots
- Run repo-stats.sh for git churn data
- Cross-reference: files with BOTH high churn AND high TODO count are hotspots
- List largest files (potential god objects)
- Check for test coverage gaps (files with no corresponding test file)

## Pass 4: Architecture
- Identify directory conventions (src/lib/app/pages/routes/etc.)
- Use Grep to trace data flow patterns (API routes → handlers → DB)
- Map the API surface (exported functions, route definitions, endpoints)
- Identify design patterns in use (MVC, clean arch, etc.)

## Pass 5: Summary
- Generate an ASCII architecture diagram showing main components and data flow
- Create a key findings table (hotspots, risks, strengths)
- List recommended next steps for someone new to the codebase

## Output

Present the full report inline. If the user wants it saved, write to `./autopsy-report.md`.

Keep each section concise. Use tables and ASCII art, not walls of text.
```

**Step 3: Commit**

```bash
git add repo-autopsy/
git commit -m "feat: add /autopsy skill — 5-pass structured codebase analysis"
```

---

### Task 9: Session lifecycle

**Files:**
- Create: `session-lifecycle/scripts/gather-context.sh`
- Create: `session-lifecycle/hooks/session-start.sh`
- Create: `session-lifecycle/hooks/hooks.json`

**Step 1: Write gather-context.sh**

```bash
#!/usr/bin/env bash
# Gather session context: memory, git history, active loops, daily log.
# Output: formatted brief to stdout.
# Must complete in <5 seconds. Failures skip silently.
set -euo pipefail

BRIEF="## Session Brief — $(date '+%Y-%m-%d %H:%M')\n"

# Project detection
PROJECT_NAME=""
PROJECT_PATH="$PWD"
if [[ -f "package.json" ]]; then
  PROJECT_NAME=$(python3 -c "import json; print(json.load(open('package.json')).get('name',''))" 2>/dev/null || echo "")
fi
if [[ -z "$PROJECT_NAME" ]] && [[ -d ".git" ]]; then
  PROJECT_NAME=$(basename "$PWD")
fi
if [[ -n "$PROJECT_NAME" ]]; then
  BRIEF="${BRIEF}\n**Project:** ${PROJECT_NAME} (${PROJECT_PATH})\n"
fi

# Recent git commits
if git rev-parse --git-dir > /dev/null 2>&1; then
  COMMITS=$(git log --oneline --format="  %h  %s (%cr)" -5 2>/dev/null || echo "")
  if [[ -n "$COMMITS" ]]; then
    BRIEF="${BRIEF}\n**Recent work:**\n${COMMITS}\n"
  fi
fi

# Active ralph loops
RALPH_STATE=".claude/ralph-loop.local.md"
if [[ -f "$RALPH_STATE" ]]; then
  ITERATION=$(sed -n 's/^iteration: *//p' "$RALPH_STATE" 2>/dev/null || echo "?")
  MAX=$(sed -n 's/^max_iterations: *//p' "$RALPH_STATE" 2>/dev/null || echo "?")
  RECIPE=$(sed -n 's/^recipe: *"*\([^"]*\)"*/\1/p' "$RALPH_STATE" 2>/dev/null || echo "prompt")
  BRIEF="${BRIEF}\n**Active loop:** ralph-${RECIPE} iteration ${ITERATION}/${MAX}\n"
fi

# Memory file (project-specific)
# Try to find matching memory file for current project path
SAFE_PATH=$(echo "$PROJECT_PATH" | sed 's|/|-|g' | sed 's|^-||')
MEMORY_FILE="$HOME/.claude/projects/${SAFE_PATH}/memory/MEMORY.md"
if [[ -f "$MEMORY_FILE" ]]; then
  # Extract first 10 non-empty lines as key notes
  NOTES=$(grep -v '^#' "$MEMORY_FILE" | grep -v '^$' | head -10 2>/dev/null || echo "")
  if [[ -n "$NOTES" ]]; then
    BRIEF="${BRIEF}\n**Memory notes:**\n${NOTES}\n"
  fi
fi

# Daily log (opt-in)
DAILY_DIR="$HOME/Documents/developer/daily"
DAILY_FILE="$DAILY_DIR/$(date '+%Y-%m-%d').md"
if [[ -f "$DAILY_FILE" ]]; then
  DAILY=$(tail -5 "$DAILY_FILE" 2>/dev/null || echo "")
  if [[ -n "$DAILY" ]]; then
    BRIEF="${BRIEF}\n**Today's log:**\n${DAILY}\n"
  fi
fi

echo -e "$BRIEF"
```

**Step 2: Write session-start.sh**

```bash
#!/usr/bin/env bash
# Session start hook — injects context brief.
# Called by Claude Code on session start.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run gather-context with 4-second timeout
timeout 4 "$SCRIPT_DIR/../scripts/gather-context.sh" 2>/dev/null || true
```

**Step 3: Write hooks.json**

```json
{
  "description": "Session lifecycle — auto-inject context on session start",
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/session-lifecycle/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

**Step 4: Commit**

```bash
git add session-lifecycle/
git commit -m "feat: add session lifecycle — auto-inject context brief on session start"
```

---

### Task 10: Install script

**Files:**
- Create: `install.sh`
- Create: `uninstall.sh`

**Step 1: Write install.sh**

```bash
#!/usr/bin/env bash
# Install claude-tools by creating a symlink in ~/.claude/plugins/
set -euo pipefail

TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins/local"
LINK_NAME="claude-tools"

mkdir -p "$PLUGIN_DIR"

# Create symlink
if [[ -L "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Updating existing symlink..."
  rm "$PLUGIN_DIR/$LINK_NAME"
elif [[ -e "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Error: $PLUGIN_DIR/$LINK_NAME exists and is not a symlink" >&2
  exit 1
fi

ln -s "$TOOL_DIR" "$PLUGIN_DIR/$LINK_NAME"

# Make scripts executable
find "$TOOL_DIR" -name "*.sh" -exec chmod +x {} \;

echo "✅ claude-tools installed"
echo "   Symlink: $PLUGIN_DIR/$LINK_NAME → $TOOL_DIR"
echo ""
echo "Available commands:"
echo "   /ralph-tdd        TDD ralph loop"
echo "   /ralph-refactor   Refactoring ralph loop"
echo "   /ralph-greenfield Greenfield ralph loop"
echo "   /ralph-review     Code review ralph loop"
echo "   /ralph-prd        PRD-driven ralph loop"
echo "   /autopsy          Structured codebase analysis"
echo ""
echo "Session lifecycle hook will auto-inject context on next session start."
echo ""
echo "⚠️  Restart Claude Code for changes to take effect."
```

**Step 2: Write uninstall.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$HOME/.claude/plugins/local"
LINK_NAME="claude-tools"

if [[ -L "$PLUGIN_DIR/$LINK_NAME" ]]; then
  rm "$PLUGIN_DIR/$LINK_NAME"
  echo "✅ claude-tools uninstalled"
else
  echo "claude-tools not installed (no symlink at $PLUGIN_DIR/$LINK_NAME)"
fi
```

**Step 3: Commit**

```bash
git add install.sh uninstall.sh
git commit -m "feat: add install/uninstall scripts — symlinks plugin into ~/.claude/plugins/local"
```

---

### Task 11: Integration test — end-to-end smoke test

**Step 1: Run install**

```bash
./install.sh
```

**Step 2: Verify plugin discovery**

Check that Claude Code would discover the plugin manifest:

```bash
ls -la ~/.claude/plugins/local/claude-tools/.claude-plugin/plugin.json
```

**Step 3: Verify script executability**

```bash
# Skill injection
./skill-inject/scripts/inject-skills.sh "test-driven-development" | head -5

# PRD scripts
./ralph-prd/scripts/prd-init.sh "smoke-test" '[{"title":"Test story","prompt":"Do nothing"}]'
./ralph-prd/scripts/prd-next.sh
./ralph-prd/scripts/prd-mark.sh "smok-01"
rm prd.json

# Repo stats
./repo-autopsy/scripts/repo-stats.sh .

# Session context
./session-lifecycle/scripts/gather-context.sh
```

**Step 4: Verify all commands exist**

```bash
ls ralph-recipes/commands/*.md
ls ralph-prd/commands/*.md
ls repo-autopsy/commands/*.md
```

**Step 5: Commit any fixes**

```bash
git add -A
git commit -m "fix: integration test fixes"
```

---

### Task 12: Final README

**Files:**
- Modify: `README.md`

**Step 1: Write comprehensive README**

Cover: what it is, install, all 6 commands with examples, architecture overview, how to create custom recipes, uninstall.

**Step 2: Final commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README with usage examples"
```
