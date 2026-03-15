# personal/skills

Single source of truth for reusable Claude-style `SKILL.md` skills.

## Layout

- `.claude/skills/<skill-name>/SKILL.md`: skill modules
- `.claude/packs/**`: YAML manifests (ordered lists of skills)
- `scripts/skillsctl`: install/sync skills into a target project and write local install state

## Prereqs

- `python3`
- `yq` (mikefarah/yq)
- `rsync` (for `--mode copy`)

## Install/Sync Into A Project

This installs skills into `<project>/.claude/skills/` and writes a local-only state file:

- `<project>/.claude/skills/.skillsctl-state.yaml` (gitignored)

Example:

```bash
./scripts/skillsctl sync \
  --project /path/to/your/project \
  --pack .claude/packs/install/default.yaml \
  --mode copy
```

Development mode (changes in this repo reflect immediately in the project):

```bash
./scripts/skillsctl sync --project /path/to/your/project --mode symlink
```

Use a project-owned pack (recommended for reproducible installs). Store the pack in the project, commit it, and point `skillsctl` at it:

```bash
./scripts/skillsctl sync \
  --project /path/to/your/project \
  --pack /path/to/your/project/.claude/packs/install/default.yaml
```

This also copies `.claude/packs/` into the target project by default (skipping files that already exist). Disable with:

```bash
./scripts/skillsctl sync --project /path/to/your/project --no-install-packs
```

By default, `skillsctl` also ensures `.gitignore` contains:

```
.claude/skills/.skillsctl-state.yaml
```

To replace an existing installed skill directory/symlink, pass `--force`.

## Inspect Local Install State

```bash
./scripts/skillsctl status --project /path/to/your/project
```

## Packs

Packs are YAML manifests that list skills by name, in the order they should be installed or executed.

- Install pack (what to install): `.claude/packs/install/default.yaml`
- Verify pack (what to run): `.claude/packs/verify/default.yaml`

Pack schema v1:

```yaml
schema_version: 1
id: install-default
skills:
  - manage-skills
  - verify-implementation
```

## Versioning / Deployment

This repo is the source of truth. For deployment, pin the repo to a git tag or commit SHA (e.g. `v0.1.0`) and run `scripts/skillsctl sync` from that checkout.
