# Storage Schema

Use this reference when a skill needs exact file shapes for `~/gdrive/.data`.

## Root

Allowed root entries:

```text
registry.yaml
.lock
.gitkeep
<category>/
```

`registry.yaml` tracks datasets:

```yaml
version: 1
base_path: ~/gdrive/.data
updated: "2026-06-26"
datasets:
  - id: content/naver-premium
    category: content
    dataset: naver-premium
    owner_skill: naver-core
    path: content/naver-premium
    dataset_path: content/naver-premium/dataset.yaml
    state_path: content/naver-premium/state.yaml
    updated: "2026-06-26"
```

## Dataset

Each dataset directory must contain:

```text
dataset.yaml
state.yaml
index/
records/
raw/
runs/
tmp/
```

`dataset.yaml`:

```yaml
version: 1
id: content/naver-premium
category: content
dataset: naver-premium
owner_skill: naver-core
created: "2026-06-26T09:30:00+09:00"
updated: "2026-06-26T09:30:00+09:00"
layout:
  records: records
  raw: raw
  index: index
  runs: runs
  tmp: tmp
```

`state.yaml`:

```yaml
version: 1
dataset_id: content/naver-premium
updated: "2026-06-26T09:30:00+09:00"
latest_record_at: null
latest_record_id: null
cursor: null
stats:
  records: 0
  raw: 0
```

## Records

Domain skills choose the record format.
Prefer one durable record per logical object.

For large text archives, prefer:

```text
records/YYYY/MM/YYYY-MM-DD__stable-id__short-title.md
raw/stable-id.html
```

For small cumulative trackers, a domain skill may use one YAML file under the dataset directory.
Do not use a single huge YAML file for large article bodies or binary-like data.

## Indexes

Use `index/` for lookup files.
Common examples:

```text
index/latest.yaml
index/by_date.yaml
index/by_source.yaml
index/records.yaml
```

Indexes are derived data.
If an index is corrupt, the domain skill should be able to rebuild it from `records/` and `raw/`.

## Run Logs

Write one run log per batch operation:

```text
runs/2026-06-26T093000+0900.yaml
```

Run log shape:

```yaml
version: 1
dataset_id: content/naver-premium
started_at: "2026-06-26T09:30:00+09:00"
finished_at: "2026-06-26T09:31:10+09:00"
status: success
operation: update
added: 3
updated: 1
skipped: 12
errors: []
```

## Conflict Handling

Because the base path is inside Google Drive, detect conflict files before writing.
Common conflict markers include filenames containing:

- `conflicted copy`
- `Conflict`
- `sync conflict`

If a conflict is found, stop and report the path.
Do not merge conflict files automatically.
