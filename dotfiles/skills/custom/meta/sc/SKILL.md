---
name: sc
description: Manage the centralized skill registry via the `sc` CLI. Browse, deploy, add, remove, update, import, and sync skills across agents and VMs.
---

# sc — Skill Registry Manager

Operate the `sc` CLI to manage skills registered in `skills/registry.yaml`.

## Quick Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `sc list` | Browse skills | `sc list --source custom --tag dev --format json` |
| `sc info <name>` | Detail for one skill | `sc info openspec` |
| `sc deploy <profile>` | Symlink skills to project | `sc deploy dev --target ~/proj` |
| `sc add <name>` | Register new skill | `sc add my-skill --source custom --agent claude --tags dev` |
| `sc remove <name>` | Unregister skill | `sc remove old-skill --delete-files --force` |
| `sc update <name>` | Edit metadata | `sc update openspec --add-tags marketing` |
| `sc import <path>` | Import external skill | `sc import ~/other/.claude/skills/cool --tags dev` |
| `sc install` | Reinstall downloaded skills | `sc install --force` |
| `sc verify` | Check registry consistency | `sc verify` |
| `sc scan` | Find unregistered skills | `sc scan --register` |
| `sc diff` | Compare registry vs filesystem | `sc diff` |

## Location

The `sc` binary lives at `~/.skills/dotfiles/bin/sc` (or wherever the repo is cloned).
The registry is at `~/.skills/dotfiles/skills/registry.yaml`.

## Core Concepts

### Registry (`skills/registry.yaml`)

Single source of truth. Every skill has:

- **name** — unique identifier (kebab-case)
- **source** — `custom` | `downloaded` | `builtin`
- **agent** — `claude` | `codex` | `gemini` | `opencode` | `universal`
- **tags** — list used for profile matching (e.g. `[dev, openspec]`)
- **path** — relative to repo root (custom) or absolute (`~/...` for external)
- **description** — one-line summary

### Profiles

Predefined tag sets for deployment:

| Profile | Tags | Use case |
|---------|------|----------|
| `dev` | dev, openspec, util, meta | General development |
| `marketing` | content, social, marketing | Content/SNS |
| `maple` | maple, content, imagegen, youtube | MapleStory BGM |
| `youtube` | youtube, content, imagegen | YouTube production |
| `threads` | social, content, marketing | Threads automation |
| `full` | * (all) | Everything |

### Deployment

`sc deploy <profile> --target <dir>` creates symlinks in `.claude/skills/` (or `.codex/skills/` with `--agent codex`).

## Workflows

### Browse and inspect

```bash
# List all skills
sc list

# Filter by source/tag/agent
sc list --source custom --tag dev
sc list --agent codex --format json

# Get details
sc info openspec
```

### Add a new custom skill

```bash
# Register + create SKILL.md template
sc add my-new-skill \
  --source custom \
  --agent claude \
  --tags dev,util \
  --description "What this skill does"

# Edit the generated SKILL.md
# Path: skills/custom/dev/my-new-skill/SKILL.md
```

### Update skill metadata

```bash
# Add tags
sc update openspec --add-tags marketing

# Remove tags
sc update openspec --remove-tags util

# Replace all tags
sc update openspec --set-tags dev,spec

# Change description
sc update openspec --description "New description"

# Change agent compatibility
sc update openspec --agent universal
```

### Remove a skill

```bash
# Registry only (keeps files)
sc remove old-skill --force

# Registry + delete SKILL.md and directory
sc remove old-skill --delete-files --force
```

### Deploy to a project

```bash
# Deploy by profile
sc deploy dev --target ~/my-project

# Preview first
sc deploy dev --target ~/proj --dry-run

# Deploy with cleanup of stale symlinks
sc deploy dev --target ~/proj --clean

# Deploy for Codex
sc deploy dev --target ~/proj --agent codex
```

### Import from another location

```bash
# Import from another project's skills
sc import ~/other-project/.claude/skills/cool-skill --tags dev

# Import with custom name/category
sc import ~/path/to/skill --name my-name --category util --tags dev
```

### Health checks

```bash
# Validate registry (required fields, paths, duplicates)
sc verify

# Compare registry vs actual filesystem
sc diff

# Find unregistered skills on disk
sc scan

# Auto-register found skills
sc scan --register
```

### Multi-VM sync

```bash
# On VM-A: make changes, push
sc add new-tool --source custom --agent claude --tags dev
git add -A && git commit -m "add new-tool" && git push

# On VM-B: pull, reinstall, deploy
git pull
sc install          # reinstall downloaded skills
sc diff             # verify sync
sc deploy dev --target ~/project
```

## Rules

- Always use `--force` flag when running non-interactively (AI agents cannot respond to y/N prompts)
- After `sc add`, edit the generated `SKILL.md` template with actual skill instructions
- After `sc remove`, run `sc deploy <profile> --target <dir> --clean` to remove stale symlinks
- Use `sc verify` after bulk changes to ensure registry consistency
- Use `sc diff` to detect drift between registry and filesystem
- Tags determine which profiles include a skill — choose tags carefully
- Skill names must be unique and kebab-case
- Valid sources: `custom`, `downloaded`, `builtin`
- Valid agents: `claude`, `codex`, `gemini`, `opencode`, `universal`
- `sc list --format json` is best for programmatic consumption
- The registry sorts skills alphabetically by name within source groups

## Output Formats

- **table** (default) — human-readable aligned columns
- **json** — `sc list --format json` — array of skill objects
- **yaml** — `sc list --format yaml` — YAML list

## Error Handling

- Typo in skill name → `sc` suggests similar names via fuzzy matching
- Missing required fields → `sc verify` reports errors
- Duplicate names → `sc add` rejects with error
- Missing SKILL.md → `sc verify` warns, `sc deploy` skips with warning
