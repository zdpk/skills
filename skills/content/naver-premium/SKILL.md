---
name: naver-premium
description: "Collect and update Naver Premium content archives from the user's already logged-in paid Naver browser session. Use when the user starts commands with the naver: prefix, asks to add/update/backfill/status/search Naver Premium channels, or wants paid-access Naver Premium article bodies saved locally through naver-core and data-store."
---

# Naver Premium

Respond in Korean by default.

Use this skill for `naver:` commands.
Do not use the old `n:` prefix.

This skill collects from Naver Premium through the user's already logged-in browser.
It does not own local storage schemas.
For storage, apply `naver-core`.

## Commands

Support these user commands:

- `naver: add-channel <url>`
- `naver: backfill <channel_key-or-url>`
- `naver: update`
- `naver: status`
- `naver: search <query>`
- `naver: validate`

If the user writes an old `n:` command, interpret it as `naver:` and mention the prefix change once.

## Browser Access

Use the existing logged-in browser session.
Do not create a new login flow unless the user explicitly asks to log in manually.

Rules:

- Do not bypass paywalls.
- Do not save cookies, tokens, session files, passwords, or browser profiles.
- Stop and report `login_required` if the page needs login.
- Save `locked` metadata only when the logged-in account cannot access the body.
- Save full body only for content visible to the user's account.

For collection details, read:

```text
references/browser-workflow.md
```

## Storage

Use `naver-core` for all persistence.

Dataset:

```text
~/gdrive/.data/content/naver-premium/
```

Before collecting a new channel, ensure the dataset exists:

```bash
python3 /Users/x/workspace/dev/skills/skills/core/data-store/scripts/datastore.py init --category content --dataset naver-premium --owner-skill naver-core
```

## Update Workflow

1. Open the target Naver Premium channel/category page in the logged-in browser.
2. Extract channel metadata, categories, article URLs, titles, and published times.
3. Compare against `naver-core` indexes and `state.yaml`.
4. Revisit a 24-48 hour overlap window to avoid same-time cursor misses.
5. Open accessible article pages and extract visible body content.
6. Pass normalized records to `naver-core`.
7. Validate the dataset.
8. Report added, updated, skipped, locked, and failed counts.

Use `(published_at, article_id)` as the cursor.
Do not rely on date alone.

## Backfill Helper

For repeatable backfill and resume work, use:

```text
scripts/backfill-helper.mjs
```

The helper is designed to be imported inside the Chrome browser-control Node session after a logged-in Chrome `tab` is available:

```js
const helper = await import("file:///Users/x/workspace/dev/skills/skills/content/naver-premium/scripts/backfill-helper.mjs");
await helper.collectLinksByScrolling(tab, {
  startUrl: "https://contents.premium.naver.com/pangyonevergiveup/pangyobulpae/contents",
  expectedTotal: 832,
  maxScrolls: 30
});
await helper.processNextArticles(tab, { batchSize: 10 });
helper.rebuildIndexes();
```

Use small batches, normally `batchSize: 10`.
The helper writes each article immediately and updates `tmp/naver-premium-current-batch.json` after every article.

From a normal shell, use the helper only for local state checks and index rebuilds:

```bash
node /Users/x/workspace/dev/skills/skills/content/naver-premium/scripts/backfill-helper.mjs progress
node /Users/x/workspace/dev/skills/skills/content/naver-premium/scripts/backfill-helper.mjs rebuild-indexes
```

## Search

For `naver: search`, search local files first:

```text
~/gdrive/.data/content/naver-premium/records/
~/gdrive/.data/content/naver-premium/index/
```

Do not browse Naver for search unless the user asks for a live refresh.
