---
name: verify-skillpack
description: Verify pack YAMLs reference existing skills and follow the pack schema.
---

# verify-skillpack

## Scope

Validate pack manifests under `.claude/packs/**`.

## Pack Schema (v1)

Required keys:
- `schema_version: 1`
- `id: <string>`
- `skills: [<skill-name>, ...]`

## Checks

1. Each pack file is valid YAML and includes required keys.
2. Each listed skill name exists at `.claude/skills/<skill-name>/SKILL.md`.
3. Verify pack does not include `verify-implementation` (avoid recursion).

## Output

- List of invalid packs with file paths
- List of missing skills referenced by packs
- Suggested edits to fix packs

