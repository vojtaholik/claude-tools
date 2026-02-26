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
