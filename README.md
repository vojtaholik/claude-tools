# claude-tools

A toolkit for Claude Code: ralph loop recipes, PRD-driven dev loops, repo autopsy, and session lifecycle hooks.

```
                    ┌─────────────────────────────┐
                    │        claude-tools          │
                    │   "don't stop til it's done" │
                    └──────────────┬──────────────┘
                                   │
          ┌────────────┬───────────┼───────────┬────────────┐
          │            │           │           │            │
    ┌─────┴─────┐ ┌───┴───┐ ┌────┴────┐ ┌────┴────┐ ┌────┴────┐
    │   ralph   │ │ ralph │ │  repo   │ │ session │ │  skill  │
    │  recipes  │ │  prd  │ │ autopsy │ │  life-  │ │ inject  │
    │           │ │       │ │         │ │  cycle  │ │         │
    │ tdd       │ │ init  │ │ 5-pass  │ │ context │ │ resolve │
    │ refactor  │ │ next  │ │ analysis│ │ brief   │ │ combine │
    │ greenfield│ │ mark  │ │         │ │ on start│ │ inject  │
    │ review    │ │ hook  │ │         │ │         │ │         │
    └───────────┘ └───────┘ └─────────┘ └─────────┘ └─────────┘
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- `python3` (used for JSON parsing in hooks and scripts)
- `bash`, `git`, standard Unix tools

## Install

```bash
git clone <this-repo> ~/Documents/developer/claude-tools
cd ~/Documents/developer/claude-tools
./install.sh
```

Creates a symlink in `~/.claude/plugins/local/claude-tools`. Restart Claude Code after install.

## Commands

### `/ralph-tdd`

TDD ralph loop. Write failing test, implement, green, refactor, repeat.

```
> /ralph-tdd
Target: src/utils/parser.ts
Scope: focus on edge cases, use vitest
```

### `/ralph-refactor`

Safe refactoring loop. Tests must stay green on every change.

```
> /ralph-refactor
Target: src/api/handlers.ts
Scope: extract duplication, keep exports stable
```

### `/ralph-greenfield`

Build something from scratch in a loop. Needs done criteria.

```
> /ralph-greenfield
Target: CLI tool that converts CSV to JSON
Scope: no external deps, node only
Done criteria: handles stdin, files, and --help flag
```

### `/ralph-review`

Two-pass code review: validator (bugs, security, types) then minifier (dead code, over-abstraction).

```
> /ralph-review
Target: src/
Scope: focus on security, ignore test files
```

### `/ralph-prd`

PRD-driven autonomous loop. Works through stories in `prd.json`.

```
> /ralph-prd init
```

Interactive setup, or provide stories directly:

```json
{
  "project": "my-app",
  "stories": [
    {
      "id": "myap-01",
      "title": "Auth system",
      "prompt": "Implement JWT auth with refresh tokens...",
      "status": "pending",
      "priority": 1,
      "skills": ["test-driven-development"]
    },
    {
      "id": "myap-02",
      "title": "User profile API",
      "prompt": "CRUD endpoints for user profiles...",
      "status": "pending",
      "priority": 2,
      "skills": []
    }
  ]
}
```

The stop hook auto-marks stories done and feeds the next one. Runs until all stories complete or max iterations hit.

### `/autopsy`

5-pass structured codebase analysis: structure, dependencies, hotspots, architecture, summary. Generates ASCII architecture diagrams and actionable findings.

```
> /autopsy
> /autopsy https://github.com/user/repo
```

## Session Lifecycle

Automatic. On session start, gathers and injects a context brief:

- Project name + path
- Last 5 git commits
- Active ralph loop status
- Memory notes (if any)
- Daily log entries (opt-in, see below)

No command needed. Runs via the `SessionStart` hook.

### Daily log (opt-in)

To include daily log entries in your session brief, set `CLAUDE_TOOLS_DAILY_DIR` in your shell profile:

```bash
# ~/.zshrc or ~/.bashrc
export CLAUDE_TOOLS_DAILY_DIR="$HOME/Documents/developer/daily"
```

Expects files named `YYYY-MM-DD.md` in that directory. Skipped if unset.

## Architecture

```
claude-tools/
├── .claude-plugin/
│   └── plugin.json          # manifest: commands + hooks
├── shared/
│   └── utils.sh             # frontmatter parser, skill resolver
├── skill-inject/
│   └── scripts/
│       └── inject-skills.sh  # resolve + combine SKILL.md files
├── ralph-recipes/
│   ├── scripts/
│   │   ├── recipe-config.sh  # recipe definitions (iterations, prompts)
│   │   └── start-recipe.sh   # creates ralph loop state file
│   └── commands/
│       ├── ralph-tdd.md
│       ├── ralph-refactor.md
│       ├── ralph-greenfield.md
│       └── ralph-review.md
├── ralph-prd/
│   ├── scripts/
│   │   ├── prd-init.sh       # scaffold prd.json
│   │   ├── prd-next.sh       # get next pending story
│   │   └── prd-mark.sh       # mark story done
│   ├── commands/
│   │   └── ralph-prd.md
│   └── hooks/
│       ├── hooks.json         # Stop hook config
│       └── stop-hook-prd.sh   # auto-advance stories
├── repo-autopsy/
│   ├── scripts/
│   │   └── repo-stats.sh     # file counts, churn, TODOs
│   └── commands/
│       └── autopsy.md
├── session-lifecycle/
│   ├── scripts/
│   │   └── gather-context.sh  # build session brief
│   └── hooks/
│       ├── hooks.json          # SessionStart hook config
│       └── session-start.sh    # triggers gather-context
├── install.sh
├── uninstall.sh
└── README.md
```

**How it works:**

1. `install.sh` symlinks the project into `~/.claude/plugins/local/`
2. Claude Code reads `plugin.json` to discover slash commands and hooks
3. Slash commands (`.md` files) define the prompt + allowed tools
4. Scripts do the actual work (bash + python3 for JSON)
5. Hooks fire on lifecycle events (session start, stop attempts)
6. Ralph loops persist state in `.claude/ralph-loop.local.md`
7. Skill injection resolves `SKILL.md` files from the plugin cache

## Uninstall

```bash
./uninstall.sh
```

Removes the symlink. Your files stay intact.

## Credits

Inspired by [joelhooks/pi-tools](https://github.com/joelhooks/pi-tools) and [ghuntley.com/ralph](https://ghuntley.com/ralph).
