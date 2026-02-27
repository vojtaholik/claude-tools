---
name: autopsy
description: Run structured 5-pass codebase analysis. Use when the user says /autopsy or wants to analyze a repo's structure, dependencies, hotspots, and architecture.
argument-hint: "[path or URL]"
---

# Repo Autopsy

Run a 5-pass structured analysis on a codebase. If given a GitHub URL, clone it first to a temp directory.

## Pass 1: Structure
- Use Glob to map the directory tree (depth 3)
- Run `~/.claude/plugins/local/claude-tools/repo-autopsy/scripts/repo-stats.sh` for language breakdown and file counts
- Identify entry points (main files, index files, app files)
- List config files (tsconfig, package.json, Dockerfile, etc.)

## Pass 2: Dependencies
- Read package.json / go.mod / Cargo.toml / requirements.txt
- Use Grep to find the most-imported internal files (top 10 by import count)
- Count external dependencies (prod vs dev)
- Check for circular dependencies (A imports B imports A)

## Pass 3: Hotspots
- Run `~/.claude/plugins/local/claude-tools/repo-autopsy/scripts/repo-stats.sh` for git churn data
- Cross-reference: files with BOTH high churn AND high TODO count are hotspots
- List largest files (potential god objects)
- Check for test coverage gaps (source files with no corresponding test file)

## Pass 4: Architecture
- Identify directory conventions (src/lib/app/pages/routes/etc.)
- Use Grep to trace data flow patterns (API routes -> handlers -> DB)
- Map the API surface (exported functions, route definitions, endpoints)
- Identify design patterns in use (MVC, clean arch, etc.)

## Pass 5: Summary
- Generate an ASCII architecture diagram showing main components and data flow
- Create a key findings table (hotspots, risks, strengths)
- List recommended next steps for someone new to the codebase

## Output

Present the full report inline. If the user wants it saved, write to `./autopsy-report.md`.

Keep each section concise. Use tables and ASCII art, not walls of text.
