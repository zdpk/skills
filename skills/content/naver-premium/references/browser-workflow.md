# Browser Workflow

Use the user's already logged-in browser session for Naver Premium.

## Channel Discovery

Start from a channel or category URL:

```text
https://contents.premium.naver.com/<publisher>/<channel>/category
```

Collect:

- channel name
- publisher slug
- channel slug
- category names and URLs
- article list URLs
- article titles
- visible published times

Derive `channel_key` as:

```text
<publisher>__<channel>
```

## Article Extraction

For each article URL:

1. Open the page in the logged-in browser.
2. Confirm the body is visible.
3. Extract title, URL, visible published time, category, and article body.
4. Save raw HTML only after removing script/session-sensitive content when practical.
5. Mark access as `subscriber`, `public`, `locked`, `login_required`, or `error`.

Do not attempt to bypass UI restrictions.
Do not scrape hidden paid text from scripts or API responses if it is not visible to the logged-in user.

## Incremental Updates

Read the latest cursor from `~/gdrive/.data/content/naver-premium/state.yaml`.

Fetch newest lists first.
Stop only after reaching the cursor plus an overlap window.
Use article id and checksum for dedupe.

## Failure Handling

If a page layout changes, save a run log with the failing URL and selector notes.
Do not update `state.yaml` after a failed batch unless the failure is isolated and skipped.

For large backfills, prefer `scripts/backfill-helper.mjs`.
It persists discovered links under `tmp/naver-premium-discovered-links.json` and writes every fetched article before moving to the next URL.

Use this recovery flow after browser interruption:

1. Reconnect Chrome and open or claim a logged-in Naver Premium tab.
2. Import `scripts/backfill-helper.mjs` in the browser-control Node session.
3. Run `helper.getProgress()` to inspect discovered, saved, and remaining counts.
4. Run `helper.processNextArticles(tab, { batchSize: 10 })`.
5. Run `helper.rebuildIndexes()` after each partial run or before reporting status.
