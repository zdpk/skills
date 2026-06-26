---
name: calendar-sync
description: Provider-neutral calendar and service synchronization for local todos, dated tasks, schedule notes, and event records. Use when syncing with Google Calendar, Apple Calendar, CalDAV, Todoist, Notion, Linear, or another calendar/task service; when creating update/delete/no-op sync diffs; or when maintaining mappings between local secondbrain items and external service records.
---

# Calendar Sync

Respond in Korean by default.

Use this skill as the sync layer between local records and external services.
The local record is the source of truth unless the user explicitly asks to import from a provider.

## Default Files

Read these when working with the user's local planning system:

```text
/Users/x/workspace/secondbrain/schedule/google-calendar-sync.md
/Users/x/workspace/secondbrain/schedule/google-calendar-map.json
```

For todos, receive the local item from `todo-capture` or read:

```text
/Users/x/workspace/secondbrain/lifelog/todo.md
```

Use Asia/Seoul unless the local item or provider event says otherwise.

## Sync Contract

Normalize each item before touching a provider:

```text
localId:
provider:
account:
calendarId:
remoteId:
title:
start:
end:
allDay:
timezone:
recurrence:
location:
notes:
attendees:
intent: create | update | delete | no-op
```

For tasks without a real time range, keep them as tasks.
Do not force them into timed calendar events.

## Provider Selection

- Use Google Calendar only when the user says Google, Google Calendar, or the existing mapping already points to Google.
- Use other installed connectors or documented local adapters when the user names another provider.
- If no provider is named, use the provider already present in the mapping.
- If no provider can be inferred, create a local sync plan and ask for the provider.

## Google Adapter

Prefer the Google Calendar connector when available.
If connector tools are not loaded and `tool_search` is available, discover them with `tool_search`.

Use the local `gws` workflow from `google-calendar-sync.md` only when connector access is unavailable or the user asks for the local adapter.
If `gws` fails with auth scope, revoked token, or `invalid_grant`, switch to the connector path instead of retrying local auth.

Google write rules:

- Read the target calendar window before writing.
- Search for likely duplicates by title and time.
- Prepare a create/update/delete/no-op diff first.
- Prefer patch-style updates.
- Preserve attendees, location, conference links, reminders, recurrence, and descriptions unless changing them is the sync intent.
- Treat recurrence edits and deletes as high-risk.

## Mapping

Maintain provider-neutral mapping when possible.
Keep Google mappings in `google-calendar-map.json`.
For non-Google providers, use an existing provider map if one exists.
Otherwise create a provider-specific map under `/Users/x/workspace/secondbrain/schedule/`, such as `<provider>-sync-map.json`.

Preferred fields for new mappings:

```json
{
  "localId": "todo-YYYYMMDD-NNN",
  "provider": "google-calendar",
  "calendarId": "primary",
  "remoteId": "event-id",
  "summary": "event title",
  "startDateTime": "2026-06-26T09:00:00+09:00",
  "endDateTime": "2026-06-26T09:30:00+09:00",
  "timeZone": "Asia/Seoul",
  "lastSyncedAt": "2026-06-26T00:00:00+09:00"
}
```

Use `eventId` instead of `remoteId` when updating existing Google entries that already use `eventId`.

## Apply Rules

If the user explicitly says to sync, create the diff and apply low-risk creates or patches in the same turn.

Stop for confirmation before:

- deleting external records
- editing recurring series
- changing attendees or conferencing
- moving events across days
- overwriting provider-side changes that do not match the local item

If the user only asks to "prepare", "check", "plan", or "dry-run", do not write externally.

## Result Reporting

Report:

- local item id
- provider and calendar/service target
- create/update/delete/no-op decision
- remote id or event id after apply
- mapping file update
- any unresolved conflict or missing field
