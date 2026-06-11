# agents.md — Ops/System (inherits ../AGENTS.md + /AGENTS.md)

**Scope:** scheduled tasks, modules, backlog, operating system tracker.

## Rules
- Scheduled tasks are **thin orchestrators**; shared logic lives in `modules/`. Invoke modules — don't duplicate logic. (Module convention: `modules/subagent-orchestration.md`.)
- Approved append targets: `Backlog.md`, `Operating-System.md`. Everything else = new dated file in `ScheduledTasks/`.
- Change one task's behavior → edit its spec in `ScheduledTasks/`. Change a capability used by several tasks → edit the `modules/` file. New capability used by ≥2 tasks → make it a module.

## Modules index
- `decision-log.md` — append-only keyed decision records (currency = newest-per-key)
- `subagent-orchestration.md` — game-master + maker→checker patterns
- `staleness-check.md` — detects when downstream docs rely on changed upstream sources
- `meeting-prep.md` — pre-meeting brief generation
- `meeting-ingestion.md` — post-meeting capture and decision promotion
- `inbox-triage.md` — inbox zero workflow
- `news-digest.md` — periodic news/signal digest
