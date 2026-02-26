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

echo "Ralph $RECIPE loop started"
echo "   Target: $TARGET"
echo "   Max iterations: $RECIPE_MAX_ITERATIONS"
echo "   Completion: <promise>$RECIPE_COMPLETION_PROMISE</promise>"
if [[ -n "$RECIPE_SKILLS" ]]; then
  echo "   Skills: $RECIPE_SKILLS"
fi
echo ""
echo "The loop will re-feed your prompt on each exit attempt."
echo "To cancel: /cancel-ralph"
