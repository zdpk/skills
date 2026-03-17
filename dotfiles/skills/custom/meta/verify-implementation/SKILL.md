---
name: verify-implementation
description: Run the verify pack(s) and report failures with concrete file paths.
---

# verify-implementation

## Purpose

Run verification in a repeatable way without hardcoding which `verify-*` skills exist.

The list of verification steps lives in `.claude/packs/verify/default.yaml`.

## Workflow

1. Identify the target root (default: current working directory).
   - The target should contain `.claude/skills/` and `.claude/packs/`.
2. Open `.claude/packs/verify/default.yaml` and read the ordered `skills:` list.
3. For each skill name:
   - Open `.claude/skills/<skill-name>/SKILL.md`
   - Follow that skill's workflow and record results.
4. Output:
   - Pass/fail summary
   - Concrete failures with absolute paths and suggested fixes

## Rules

- Do not embed the list of `verify-*` skills in this file.
- Prefer deterministic checks (file existence, schema validation, command dry-runs) over subjective judgement.

