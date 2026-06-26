---
name: data-store
description: Shared local file persistence layer for skills that need durable user-owned data under ~/gdrive/.data. Use when a skill needs to create, locate, validate, index, or update local datasets by category and dataset name, especially before domain skills save records, archives, indexes, state files, run logs, or raw source snapshots.
---

# Data Store

Respond in Korean by default.

Use this skill as the common persistence layer for user-owned local data.
Do not use it for fetching, scraping, analysis, or provider-specific behavior.

## Base Path

Store durable data under:

```text
~/gdrive/.data
```

Allow overriding the base path only when the user explicitly asks or when testing:

```text
DATA_STORE_ROOT=/tmp/data-store-test
```

Never save dataset records directly under `~/gdrive/.data`.
All dataset data must live under:

```text
~/gdrive/.data/<category>/<dataset>/
```

## Category Rules

Use the skill source category as the default category.

Examples:

- `skills/content/naver-premium` -> `content`
- `skills/lang/ja-core` -> `lang`
- `skills/personal/todo-capture` -> `personal`
- `skills/social/threads` -> `social`
- `skills/project/manual-sync` -> `project`

Use lowercase hyphen slugs for both `category` and `dataset`.
Do not create loose files at the data root except `registry.yaml`, `.lock`, and `.gitkeep`.

## Dataset Layout

Create each dataset with this shape:

```text
~/gdrive/.data/<category>/<dataset>/
  dataset.yaml
  state.yaml
  index/
  records/
  raw/
  runs/
  tmp/
```

Use `records/` for normalized durable records.
Use `raw/` for source snapshots such as HTML, JSON, PDFs, or original text.
Use `index/` for lookup files.
Use `state.yaml` for cursors and latest-update state.
Use `runs/` for operation logs.
Use `tmp/` only for temporary files that can be removed.

For the detailed schema, read:

```text
references/storage-schema.md
```

## Workflow

1. Resolve `category` and `dataset`.
2. Run `scripts/datastore.py init` before first write.
3. Read `registry.yaml`, `dataset.yaml`, and `state.yaml` before updates.
4. Write records under `records/` or `raw/`.
5. Update `index/` and `state.yaml`.
6. Add a compact run log under `runs/` for batch operations.
7. Run `scripts/datastore.py validate`.
8. Report the dataset path and changed files.

## Helper Script

Use the bundled helper for path resolution, dataset initialization, and validation:

```bash
python3 scripts/datastore.py resolve --category content --dataset naver-premium
python3 scripts/datastore.py init --category content --dataset naver-premium --owner-skill naver-core
python3 scripts/datastore.py import-file --category lang --dataset japanese-reading --owner-skill ja-core --source /old/path.yaml --target japanese-reading-tracker.yaml --mode move
python3 scripts/datastore.py validate
```

When called from outside the skill directory, use the absolute script path.

## Write Safety

Use atomic writes for YAML, Markdown, JSON, and generated indexes:

1. Write a temporary file in the same directory.
2. Flush and close it.
3. Rename it over the target.

When a dataset update spans multiple files, create a run log first and update `state.yaml` last.
If a Google Drive conflict file appears, stop and report it instead of merging automatically.

## Boundaries

Do not store secrets, cookies, browser sessions, OAuth tokens, or paid-service credentials.
Provider skills may store fetched content only when the user has access and asked for durable local storage.

Do not decide domain schemas here.
Domain skills define their own record fields while following this path, index, state, and run-log structure.
