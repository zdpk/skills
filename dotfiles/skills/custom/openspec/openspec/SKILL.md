---
name: openspec
description: Spec-driven development using the OpenSpec CLI (`openspec`) and an `openspec/` project directory. Use when the user mentions OpenSpec/openspec/opsx, asks for "spec first" / "선 스펙 후 구현", or you need to initialize OpenSpec, create/update change artifacts (proposal/specs/design/tasks), validate status, or archive a completed change.
---

# OpenSpec

## Overview

Use `openspec` to keep code changes aligned with a written spec: create a change, fill required artifacts, implement tasks, validate, then archive.

## Workflow

### 1) Ensure OpenSpec Is Initialized

- If the repo has no `openspec/` directory, initialize in the project root:

```bash
openspec init --tools codex
```

### 2) Create A Change (Spec First)

For any non-trivial change, create an OpenSpec change directory first:

```bash
openspec new change <change-name>
```

Use `kebab-case` and keep it short but specific (e.g. `student-personal-calendar-api`).

Check what artifacts are required / missing:

```bash
openspec status --change <change-name>
```

Get enriched, schema-aware instructions for a specific artifact (useful before writing `proposal.md`, `tasks.md`, etc.):

```bash
openspec instructions --change <change-name> <artifact>
```

### 3) Write The Artifacts

Typical flow:

- `proposal.md`: problem, goals/non-goals, constraints, risks
- `specs/…/spec.md`: requirements + scenarios (API contracts, validation, auth, error cases)
- `design.md`: implementation approach, DB/schema changes, edge cases, migrations
- `tasks.md`: executable checklist mapped to files and tests

Keep `tasks.md` concrete (file paths, commands, acceptance criteria) so implementation is mechanical.

### 4) Implement From Tasks

After artifacts are complete, implement code changes by following `tasks.md`. Keep edits scoped to the change.

### 5) Validate

Validate a specific change (use `--strict` when possible):

```bash
openspec validate <change-name> --type change --strict
```

Or validate everything:

```bash
openspec validate --all --strict
```

### 6) Archive When Done

When the change is complete, archive it (updates main specs by default):

```bash
openspec archive <change-name> -y
```

If it is tooling/doc-only and should not update specs, consider:

```bash
openspec archive <change-name> -y --skip-specs
```

## Useful Commands

```bash
openspec list
openspec list --specs
openspec show <item-name>
openspec spec show <spec-id>
openspec update
```
