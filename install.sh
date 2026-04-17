#!/usr/bin/env bash
# Install claude-tools: generate skills, plugin symlink, skill symlinks
set -euo pipefail

TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins/local"
SKILLS_DIR="$HOME/.claude/skills"
LINK_NAME="claude-tools"
INSTALL_PATH="~/.claude/plugins/local/claude-tools"

mkdir -p "$PLUGIN_DIR" "$SKILLS_DIR"

# --- Generate skills from command files ---

# command_file -> skill_name:skill_description
declare -A SKILL_MAP=(
  ["ralph-recipes/commands/ralph-tdd.md"]="ralph-tdd:Start a TDD ralph loop. Use when the user says /ralph-tdd or wants test-driven development with an autonomous loop."
  ["ralph-recipes/commands/ralph-refactor.md"]="ralph-refactor:Start a refactoring ralph loop. Use when the user says /ralph-refactor or wants safe autonomous refactoring with test safety net."
  ["ralph-recipes/commands/ralph-greenfield.md"]="ralph-greenfield:Start a greenfield ralph loop. Use when the user says /ralph-greenfield or wants to build something from scratch with an autonomous loop."
  ["ralph-recipes/commands/ralph-review.md"]="ralph-review:Start a code review ralph loop. Use when the user says /ralph-review or wants autonomous 2-pass code review (validator + minifier)."
  ["ralph-prd/commands/ralph-prd.md"]="ralph-prd:Start a PRD-driven ralph loop. Use when the user says /ralph-prd or wants autonomous story-by-story development from a prd.json config."
  ["repo-autopsy/commands/autopsy.md"]="autopsy:Run structured 5-pass codebase analysis. Use when the user says /autopsy or wants to analyze a repo's structure, dependencies, hotspots, and architecture."
)

echo "Generating skills from commands..."
for cmd_file in "${!SKILL_MAP[@]}"; do
  IFS=':' read -r skill_name skill_desc <<< "${SKILL_MAP[$cmd_file]}"
  skill_dir="$TOOL_DIR/skills/$skill_name"
  mkdir -p "$skill_dir"

  # Strip command frontmatter, replace plugin root var with install path
  body=$(awk '/^---$/{i++; next} i>=2' "$TOOL_DIR/$cmd_file" | sed "s|\${CLAUDE_PLUGIN_ROOT}|$INSTALL_PATH|g")

  # Check if command has argument-hint
  arg_hint=$(sed -n '/^---$/,/^---$/p' "$TOOL_DIR/$cmd_file" | grep '^argument-hint:' | sed 's/^argument-hint: *//' | tr -d '"')

  # Write SKILL.md with skill frontmatter
  {
    echo "---"
    echo "name: $skill_name"
    echo "description: $skill_desc"
    [[ -n "$arg_hint" ]] && echo "argument-hint: \"$arg_hint\""
    echo "---"
    echo "$body"
  } > "$skill_dir/SKILL.md"

  echo "   Generated skill: $skill_name"
done

# --- Plugin symlink ---

if [[ -L "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Updating plugin symlink..."
  rm "$PLUGIN_DIR/$LINK_NAME"
elif [[ -e "$PLUGIN_DIR/$LINK_NAME" ]]; then
  echo "Error: $PLUGIN_DIR/$LINK_NAME exists and is not a symlink" >&2
  exit 1
fi
ln -s "$TOOL_DIR" "$PLUGIN_DIR/$LINK_NAME"

# --- Skill symlinks ---

SKILLS=(ralph-tdd ralph-refactor ralph-greenfield ralph-review ralph-prd autopsy)
for skill in "${SKILLS[@]}"; do
  target="$TOOL_DIR/skills/$skill"
  link="$SKILLS_DIR/$skill"
  if [[ -L "$link" ]]; then
    rm "$link"
  elif [[ -e "$link" ]]; then
    echo "Warning: $link exists and is not a symlink, skipping" >&2
    continue
  fi
  ln -s "$target" "$link"
  echo "   Linked skill: /$skill"
done

# --- Vojta prompting skills (derived from Anthropic's prompting best practices) ---

VOJTA_SKILLS=(
  vojta-frontend-design
  vojta-concise
  vojta-act
  vojta-research-first
  vojta-parallel-tools
  vojta-bug-hunt
  vojta-minimal
  vojta-investigate
  vojta-persist
  vojta-no-hardcode
  vojta-confirm
  vojta-deep-research
  vojta-prose
  vojta-design-options
  vojta-cleanup
)
for skill in "${VOJTA_SKILLS[@]}"; do
  target="$TOOL_DIR/vojta-skills/$skill"
  link="$SKILLS_DIR/$skill"
  if [[ -L "$link" ]]; then
    rm "$link"
  elif [[ -e "$link" ]]; then
    echo "Warning: $link exists and is not a symlink, skipping" >&2
    continue
  fi
  ln -s "$target" "$link"
  echo "   Linked skill: /$skill"
done

# Make scripts executable
find "$TOOL_DIR" -name "*.sh" -exec chmod +x {} \;

echo ""
echo "claude-tools installed"
echo "   Plugin: $PLUGIN_DIR/$LINK_NAME -> $TOOL_DIR"
echo ""
echo "Available commands:"
echo "   /ralph-tdd        TDD ralph loop"
echo "   /ralph-refactor   Refactoring ralph loop"
echo "   /ralph-greenfield Greenfield ralph loop"
echo "   /ralph-review     Code review ralph loop"
echo "   /ralph-prd        PRD-driven ralph loop"
echo "   /autopsy          Structured codebase analysis"
echo ""
echo "Session lifecycle hook auto-injects context on session start."
echo ""
echo "Restart Claude Code for changes to take effect."
