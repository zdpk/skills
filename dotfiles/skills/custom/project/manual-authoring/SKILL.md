---
name: "manual-authoring"
description: "Use when the user wants Codex to write or revise the SNPortal technical manual prose, module summaries, API explanations, architecture notes, release-facing documentation, or other narrative docs under docs/manual and docs/. Use this after deterministic counters have been synced. Do not use for endpoint/schema/table counts alone; use manual-sync for that."
---

# Manual Authoring

Use this skill when the SNPortal manual text has drifted from the codebase and the user wants Codex to update the writing, not just the numbers.

## Scope

- `docs/manual/*.html`
- `docs/manual/README.md`
- `docs/API_REFERENCE.md`
- other project docs under `docs/` when the content is explanatory or release-facing

Do not use this skill for deterministic counters by itself. If counts, endpoint totals, schema totals, JPA entity totals, or Atlas table totals may have changed, run `$manual-sync` first.

## Primary source of truth

Author docs from the code changes themselves.

- Prefer the repo-local helper first:
  - `git manual-authoring-context`
  - underlying command: `python3 scripts/manual_authoring_context.py --include-staged`
- That helper resolves the default review range as:
  - last commit with trailer `Manual-Authoring: true`
  - otherwise the last commit that touched `docs/manual` or `docs/API_REFERENCE.md`
  - then compare that base to `HEAD`
- For uncommitted work, include staged changes as an extra overlay.
- For committed work, inspect `git show <commit>` or the resolved commit range next.
- Use the changed files to decide which manual pages need updates.
- Only after the change scope is clear should you edit prose.

## Recommended model use

- Prefer a strong general writing/coding model for document drafting and revision.
- Treat this as a manual authoring pass, not a commit hook task.
- Keep deterministic facts grounded in the repository or runtime outputs, not model memory.

## Workflow

1. Run `git manual-authoring-context`.
2. Inspect the resolved diff context.
   - Default: last `Manual-Authoring: true` commit to `HEAD`
   - Fallback: last manual-doc-touch commit to `HEAD`
   - Optional overlays: `git diff --cached`, `git show <commit>`
3. Read the changed code, tests, routes, schemas, and existing docs tied to that diff.
4. If manual counters may be stale, run `python3 scripts/sync_manual_stats.py` first or invoke `$manual-sync`.
5. Identify the minimal set of docs that should change. Avoid broad rewrites when a focused update is enough.
6. Update prose to match the implementation:
   - module responsibilities
   - request and response behavior
   - permissions and roles
   - architecture boundaries
   - data ownership and lifecycle
   - user-visible flows
7. Keep terminology consistent with the current codebase. If a rename is underway, document the current canonical name and remove stale wording.
8. Verify every concrete claim against code or runtime output.
9. Commit the manual pass with `git manual-authoring-commit`.
   - underlying template: `.gitmessage-manual-authoring.txt`
   - required trailer: `Manual-Authoring: true`
10. Summarize what changed and what was intentionally left untouched.

## Writing rules

- Be concrete and implementation-aligned.
- Prefer short declarative sentences over marketing language.
- Do not invent roadmap claims, coverage claims, or support guarantees.
- Do not restate generated numbers manually if they are already maintained by `$manual-sync`.
- Preserve existing document structure unless the user asked for a restructure.
- When updating HTML manual pages, keep the visual style and markup patterns already used in the file.

## Common tasks

- Refresh a module page after new backend or frontend features landed
- Rewrite outdated API explanations after endpoint changes
- Align architecture notes with new package boundaries
- Update user flow docs after payment, order, or student features changed
- Clean up inconsistent naming across manual pages
- Write release-note style manual updates from a specific commit or PR diff

## Notes

- `manual-sync` and `manual-authoring` are complementary:
  - `$manual-sync` for counters and mechanically derived facts
  - `$manual-authoring` for explanatory text and document quality
- If the user wants both, run sync first, then do the authoring pass.
- The default review unit is the diff, not the whole repository.
- A repo-local pre-push warning can remind the user when source changes have outpaced manual prose.
- Repo-local aliases:
  - `git manual-authoring-context`
  - `git manual-authoring-commit`
