#!/usr/bin/env bash
# Session start hook — injects context brief.
# Called by Claude Code on session start.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run gather-context with 4-second timeout
timeout 4 "$SCRIPT_DIR/../scripts/gather-context.sh" 2>/dev/null || true
