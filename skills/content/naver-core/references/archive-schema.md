# Naver Archive Schema

Use this schema for `~/gdrive/.data/content/naver-premium`.

## Article Markdown

Each article record is Markdown with YAML frontmatter:

```md
---
source: naver-premium
channel_key: pangyonevergiveup__pangyobulpae
channel_name: "세상의 모든 시장 이야기"
article_id: "stable-article-id"
title: "Article title"
source_url: "https://contents.premium.naver.com/..."
category_ids: []
category_names: []
published_at: "2026-06-26T08:30:00+09:00"
fetched_at: "2026-06-26T09:30:00+09:00"
access: subscriber
content_sha256: "..."
raw_path: "raw/stable-article-id.html"
---

# Article title

Article body.
```

`access` values:

- `public`
- `subscriber`
- `locked`
- `login_required`
- `error`

## Indexes

`index/articles.yaml`:

```yaml
version: 1
updated: "2026-06-26T09:30:00+09:00"
articles:
  - article_id: stable-article-id
    title: "Article title"
    channel_key: pangyonevergiveup__pangyobulpae
    source_url: "https://contents.premium.naver.com/..."
    published_at: "2026-06-26T08:30:00+09:00"
    fetched_at: "2026-06-26T09:30:00+09:00"
    access: subscriber
    record_path: "records/2026/06/2026-06-26__stable-article-id__article-title.md"
    raw_path: "raw/stable-article-id.html"
    content_sha256: "..."
```

`index/channels.yaml`:

```yaml
version: 1
updated: "2026-06-26T09:30:00+09:00"
channels:
  - channel_key: pangyonevergiveup__pangyobulpae
    channel_name: "세상의 모든 시장 이야기"
    channel_url: "https://contents.premium.naver.com/pangyonevergiveup/pangyobulpae"
    latest_published_at: "2026-06-26T08:30:00+09:00"
    article_count: 0
```

`state.yaml` should keep the latest cursor:

```yaml
cursor:
  published_at: "2026-06-26T08:30:00+09:00"
  article_id: stable-article-id
```

## File Naming

Use lowercase ASCII slugs for filenames when possible.
Keep the original Korean title in frontmatter.

If an id is unknown, derive a stable id from the source URL.
Do not use title alone as a primary key.
