# claude-tools v1 — Design Document

Pi-tools lite for Claude Code. A modular toolkit of 5 tools that make ralph loops smarter and daily coding more fluid.

Inspired by [joelhooks/pi-tools](https://github.com/joelhooks/pi-tools).

## Architecture

**Hybrid: Skills + Hooks + CLI scripts**

- Skills = the interface (user invokes `/ralph-tdd`, `/autopsy`, etc.)
- Hooks = lifecycle events (session start, stop hook for ralph loops)
- Scripts = heavy lifting (PRD parsing, state management, skill resolution, context gathering)

Matches existing ralph-loop plugin patterns. No MCP servers, no daemons, no external infra.

## Package Structure

```
~/Documents/developer/claude-tools/
├── README.md
├── install.sh                    # symlinks hooks/skills into ~/.claude
├── uninstall.sh
│
├── ralph-recipes/                # Preset ralph loop configurations
│   ├── tdd.md                    # skill: /ralph-tdd
│   ├── refactor.md               # skill: /ralph-refactor
│   ├── greenfield.md             # skill: /ralph-greenfield
│   └── review.md                 # skill: /ralph-review
│
├── ralph-prd/                    # PRD-driven ralph loops
│   ├── prd-ralph.md              # skill: /ralph-prd
│   ├── scripts/
│   │   ├── prd-init.sh           # scaffold prd.json in project
│   │   ├── prd-next.sh           # pick next story by priority
│   │   └── prd-mark.sh           # mark story complete
│   └── hooks/
│       └── stop-hook-prd.sh      # stop hook variant for PRD mode
│
├── skill-inject/                 # Skill injection for ralph iterations
│   ├── inject.md                 # skill: /ralph-inject
│   └── scripts/
│       └── inject-skills.sh      # reads skill files, prepends to prompt
│
├── repo-autopsy/                 # Structured codebase analysis
│   ├── autopsy.md                # skill: /autopsy
│   └── scripts/
│       └── repo-stats.sh         # tokei/cloc, dep graph, hotspots
│
├── session-lifecycle/            # Context injection at session start
│   ├── lifecycle.md              # skill: /session-brief
│   ├── scripts/
│   │   └── gather-context.sh     # reads memory, daily log, project status
│   └── hooks/
│       └── session-start.sh      # auto-injects on session start
│
└── shared/
    └── utils.sh                  # common helpers (state file parsing, etc.)
```

## Tool 1: Ralph Recipes

Preset ralph loop configurations for common workflows.

### Recipes

| Skill | Prompt focus | Completion promise | Max iter | Injected skill |
|-------|-------------|-------------------|----------|----------------|
| `/ralph-tdd` | red->green->refactor cycle | ALL TESTS PASS | 15 | test-driven-development |
| `/ralph-refactor` | one refactor per pass, tests must stay green | ALL TESTS PASS + NO TYPE ERRORS | 20 | — |
| `/ralph-greenfield` | scaffold->implement->test->iterate | user-defined | 30 | — |
| `/ralph-review` | validator pass + minifier pass | ALL_CLEAN from both | 10 | — |

### Flow

Each recipe skill:
1. Asks 2-3 quick questions (target, scope, done criteria for greenfield)
2. Constructs tuned prompt
3. Fires `/ralph-loop` with appropriate flags

## Tool 2: PRD-driven Ralph

Story-by-story autonomous work from a `prd.json` file.

### prd.json format

```json
{
  "project": "auth-rewrite",
  "stories": [
    {
      "id": "auth-01",
      "title": "JWT token refresh",
      "prompt": "Implement token refresh logic in auth.ts...",
      "priority": 1,
      "skills": ["superpowers:test-driven-development"],
      "status": "done"
    },
    {
      "id": "auth-02",
      "title": "Session middleware",
      "prompt": "Add express middleware that validates...",
      "priority": 2,
      "skills": [],
      "status": "pending"
    }
  ]
}
```

### Flow

1. `/ralph-prd` — checks for `prd.json`
2. No file? Interactive scaffolding (asks project name, stories)
3. File exists? Shows status table, starts loop
4. Modified stop hook picks next `pending` story by priority
5. On story completion: `prd-mark.sh` sets `"status": "done"`
6. All stories done: loop exits

### Scripts

- `prd-init.sh` — scaffold `prd.json` from interactive input
- `prd-next.sh` — return first `pending` story sorted by priority
- `prd-mark.sh` — set story status to `done` with timestamp

## Tool 3: Skill Injection

Prepend skill SKILL.md content to each ralph iteration's prompt.

### Resolution order

```
~/.claude/plugins/*/skills/*/SKILL.md
~/.claude/plugins/marketplaces/*/plugins/*/skills/*/SKILL.md
./.claude/skills/*/SKILL.md
```

### Constraints

- Max 3 skills per iteration (warn if more requested)
- Total injected content capped at ~4000 words (truncate with note)
- Unresolvable skills logged as warning, skipped

### Usage

- Per-recipe: `/ralph-tdd` auto-injects `test-driven-development`
- Per-story: `"skills": ["frontend-design"]` in prd.json
- Manual: `--skills "frontend-design,modern-css"`

## Tool 4: Repo Autopsy

5-pass codebase analysis skill.

### Passes

1. **Structure** — file tree (depth 3), language breakdown, entry points, config files
2. **Dependencies** — package.json/go.mod, import graph (top 10 most imported), external dep count, circular dep check
3. **Hotspots** — git log --shortstat, most-changed files, largest files, TODO/FIXME/HACK count
4. **Architecture** — directory conventions, data flow patterns, API surface
5. **Summary** — ASCII architecture diagram, key findings table, recommended next steps

### Output

Markdown report to `./autopsy-report.md` or inline. Uses only built-in Claude Code tools (Glob, Grep, Read, Bash).

### Usage

```
/autopsy                          # current directory
/autopsy /path/to/repo            # specific repo
/autopsy https://github.com/...   # clone + analyze
```

## Tool 5: Session Lifecycle

Auto-injects context on session start via hook.

### Context gathered

| Source | What | Where |
|--------|------|-------|
| Memory | Persistent auto-memory | `~/.claude/projects/*/memory/MEMORY.md` |
| Daily log | Today's work log (opt-in) | `~/Documents/developer/daily/YYYY-MM-DD.md` |
| Project | CLAUDE.md + last 5 git commits | `.claude/CLAUDE.md` + `git log` |
| Active loops | Ralph loop state | `~/.claude/ralph-loop.local.md` |

### Brief format

```markdown
## Session Brief -- YYYY-MM-DD HH:MM

**Project:** name (path)
**Recent work:**
  - a1b2c3d  commit message (2h ago)
  - d4e5f6g  commit message (5h ago)

**Active loops:** ralph-tdd iteration 7/15

**Memory notes:**
  - relevant note 1
  - relevant note 2
```

### Constraints

- 5 second timeout — file reads and one `git log` only
- Failures skip silently
- Opt-in daily log: session end appends a line, next session reads it

## Installation

```bash
cd ~/Documents/developer/claude-tools
./install.sh
```

Symlinks skills and hooks into `~/.claude/`. Idempotent — safe to re-run.

## Not in v1 (future)

- Widgets/progress (Claude Code has no TUI widget API)
- Silent messages (no `display: false` equivalent)
- Memory RAG (needs vector DB)
- Background task batching
- MCP server versions of any tool
- Grind mode (auto-continue without ralph)
