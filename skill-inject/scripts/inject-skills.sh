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
