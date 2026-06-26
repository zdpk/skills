---
name: naver-core
description: Shared archive core for Naver content datasets. Use when storing, indexing, validating, searching, or updating locally saved Naver Premium channel/article data, especially records under the data-store dataset ~/gdrive/.data/content/naver-premium. This skill owns the local archive schema and persistence rules; browser access and Naver-specific collection are handled by naver-premium.
---

# Naver Core

Respond in Korean by default.

Use this skill as the common archive layer for Naver content.
Do not browse Naver pages or extract DOM content here.
Use `naver-premium` for browser collection.

## Storage

Use `data-store` for all durable files.

Dataset:

```text
category: content
dataset: naver-premium
path: ~/gdrive/.data/content/naver-premium/
```

Before first write, initialize the dataset:

```bash
python3 /Users/x/workspace/dev/skills/skills/core/data-store/scripts/datastore.py init --category content --dataset naver-premium --owner-skill naver-core
```

## Dataset Layout

Use the standard `data-store` layout:

```text
~/gdrive/.data/content/naver-premium/
  dataset.yaml
  state.yaml
  index/
  records/
  raw/
  runs/
  tmp/
```

Use:

- `records/` for normalized Markdown article records.
- `raw/` for source HTML or source snapshots.
- `index/` for article, channel, category, and date indexes.
- `state.yaml` for latest cursor and update state.
- `runs/` for crawl/import/update operation logs.

For exact field shapes, read:

```text
references/archive-schema.md
```

## Record Rules

Use one Markdown file per article:

```text
records/YYYY/MM/YYYY-MM-DD__article-id__short-title.md
```

Save raw source separately when available:

```text
raw/article-id.html
```

Do not store browser cookies, session data, tokens, or credentials.
Do not store locked paid body text when the user account cannot access it.

## Index Rules

Maintain derived indexes under `index/`:

```text
index/articles.yaml
index/channels.yaml
index/categories.yaml
index/by_date.yaml
index/latest.yaml
```

Use article id as the stable dedupe key.
Use `(published_at, article_id)` as the incremental cursor.
Use checksums to detect changed article body or metadata.

## Update Rules

When another skill supplies fetched article data:

1. Read `dataset.yaml`, `state.yaml`, and relevant indexes.
2. Normalize metadata and article body.
3. Write raw source first when present.
4. Write the Markdown record.
5. Rebuild or update indexes.
6. Write a run log.
7. Update `state.yaml` last.

If a Google Drive conflict file exists inside the dataset, stop and report it.
