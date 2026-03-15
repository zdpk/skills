---
name: "manual-sync"
description: "Use when the user wants to update or sync the SNPortal technical manual, API reference, or commit-time documentation counters such as OpenAPI endpoints, schemas, JPA entities, Atlas table counts, services, finders, modifiers, or test counts. Also use when installing or running the commit hook that keeps docs/manual in sync."
---

# Manual Sync

Use this skill for the SNPortal repository when manual counters or summary docs drift from the codebase.

## What this skill updates

- `docs/manual/index.html`
- `docs/manual/api-reference.html`
- `docs/manual/entities.html`
- `docs/manual/architecture.html`
- `docs/manual/module-subscription.html`
- `docs/manual/README.md`
- `docs/API_REFERENCE.md`

## Source of truth

1. Runtime OpenAPI first
   - Default URL: `http://localhost:8080/api/v3/api-docs`
   - If available, use:
     - operation count as REST endpoint count
     - path count as OpenAPI path count
     - schema count as OpenAPI schema count
2. Static repository scan
   - `src/main/kotlin/sn/snportal` for controllers, services, finders, modifiers, `@Entity`
   - `src/test/kotlin/sn/snportal` for test file and approximate test case counts
3. Atlas schema
   - `atlas/schema/*.sql`
   - Count both schema files and unique `CREATE TABLE` names separately

## Quick start

- Sync docs:
  - `python3 scripts/sync_manual_stats.py`
- Check drift without writing:
  - `python3 scripts/sync_manual_stats.py --check`
- Sync and stage updated docs:
  - `python3 scripts/sync_manual_stats.py --stage`

## Commit workflow

If the user wants commit-time sync, install the repo hook:

- `git config core.hooksPath .githooks`

Then every commit runs:

- `.githooks/pre-commit`

The hook calls:

- `python3 scripts/sync_manual_stats.py --stage`

Temporary bypass:

- `SKIP_MANUAL_SYNC=1 git commit ...`

## Workflow

1. Confirm the repo is `snportal`.
2. If the user says the local server is up, prefer runtime OpenAPI counts.
3. Run `python3 scripts/sync_manual_stats.py`.
4. Inspect the JSON summary and diff.
5. If the user wants commit automation, install the hook with `git config core.hooksPath .githooks`.
6. Mention whether runtime OpenAPI or static fallback was used.

## Notes

- `DB 테이블` and `Atlas schema files` are different metrics. Keep them separate.
- The script is project-specific. Do not reuse these counts for other repositories.
- If `http://localhost:8080/api/v3/api-docs` is unavailable, the script falls back to static controller annotation counts instead of failing.
