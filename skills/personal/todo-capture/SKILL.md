---
name: todo-capture
description: Save and maintain the user's personal todos in the local secondbrain todo ledger. Use when the user asks to add, record, update, complete, review, or organize todos, 할 일, TODO, reminders, dated tasks, waiting items, or tasks that may later be synced to a calendar or external service through calendar-sync.
---

# Todo Capture

Respond in Korean by default.

Use this skill to keep personal todos durable in the local ledger.
Do not write directly to an external calendar from this skill.
When sync is requested, save the local todo first, then use `calendar-sync`.

## Default Files

Read before editing:

```text
/Users/x/workspace/secondbrain/lifelog/todo.md
/Users/x/workspace/secondbrain/lifelog/templates/todo-entry.md
```

Use Asia/Seoul for dates unless the user gives another timezone.

## Workflow

1. Read the todo ledger.
2. Classify each item into `Now`, `Next`, `Waiting`, `Scheduled / Dated`, or `Done`.
3. Edit the smallest relevant section.
4. Update the top `Updated:` date.
5. Preserve existing wording and formatting outside the edited lines.
6. Report what changed.

## Entry Shape

Prefer a compact checkbox when no metadata is needed:

```md
- [ ] 할 일 내용
```

Use nested metadata when the item has a due date, source, context, or sync target:

```md
- [ ] 할 일 내용
  - Id: todo-YYYYMMDD-NNN
  - Context:
  - Due: YYYY-MM-DD HH:mm
  - Source:
  - Sync:
```

Generate `Id` only when it helps future sync, updates, or disambiguation.
Use the current date plus a three-digit sequence not already used that day.

## Placement Rules

- Put urgent or currently active tasks in `Now`.
- Put non-urgent backlog tasks in `Next`.
- Put blocked tasks in `Waiting`, with the blocker if known.
- Put dated tasks in `Scheduled / Dated`, prefixed with the date when useful.
- Move completed tasks to `Done` and mark them `[x]`.

If the user says only "todo 저장" or gives a short imperative, save it.
Do not ask a follow-up unless the todo cannot be understood.

## Sync Boundary

If the user asks to sync with Google Calendar, another calendar, or another service:

1. Save or update the local todo first.
2. Ensure the todo has a stable `Id`, due date/time when needed, and clear title.
3. Invoke `calendar-sync` with the local todo data.
4. Write back sync status only after the sync layer reports the result.

If a task has no date/time, do not invent a calendar slot.
Save it locally and mark sync as pending only when the user asked for sync.
