---
name: manage-skills
description: Maintain and evolve verify skills and packs as the repo changes.
---

# manage-skills

## Purpose

Keep the verification system healthy:

- verify packs stay aligned with the actual verify skills
- new/changed skills get reflected in install packs
- verification coverage doesn't silently drift

## Workflow

1. Collect recent changes:
   - Prefer `git diff --name-only` against the target branch/tag the user cares about.
2. If changes touched any of the following, run `verify-implementation`:
   - `.claude/skills/**`
   - `.claude/packs/**`
   - `scripts/skillsctl`
3. If a new skill was added, ensure at least one install pack includes it (or explicitly justify why not).
4. If a new `verify-*` skill was added, ensure it is included in `.claude/packs/verify/default.yaml` (unless explicitly excluded).
5. Summarize what changed and which packs were updated.

## Rules

- Do not hardcode the list of verify skills in this file. Use packs under `.claude/packs/**`.
- Prefer small, composable `verify-*` skills over one monolithic verifier.

