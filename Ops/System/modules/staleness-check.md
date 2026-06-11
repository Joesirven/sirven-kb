# module: staleness-check

> inherits: Ops/System/modules/subagent-orchestration.md

Reusable capability. Detects when a **downstream doc relies on an upstream source that has since changed**, so an agent never silently treats superseded information as current. Read-only — it **raises** drift, never auto-edits.

## What it guards
- A `Projects/*` doc that references a `Docs/*` synthesis (or a `Research/` card, or a `decisions.md` key).
- Any doc that quotes/derives from a canonical upstream doc.

## Triggers
- **Reactive:** when a `Projects/*` doc that references a `Docs/*` doc is created or updated → check that the reference is still fresh.
- **On retrieval:** when an agent pulls a `Docs/*` doc to use in a project, confirm currency before relying on it.
- **Periodic:** as a sweep inside `kb-audit`.

## How it checks currency (inferred, no stored "fresh" flag)
Spawn a subagent (per the inherited orchestration rules) that, for each reference, compares:
- upstream **last-modified** vs. when the downstream last synced to it;
- the upstream's `as_of` / `revisit_when` frontmatter (Research cards) — past `revisit_when` ⇒ stale;
- the nearest `decisions.md` — a **newer entry for the same decision-key** supersedes what the downstream assumed (consistent with `decision-log.md`: currency = newest-per-key, not a status flag).

## Output
A drift report to `tmp/staleness/<date>.md`: `downstream doc → upstream source → what changed → suggested action`. Fold actionable items into the brief/retro or the `kb-audit` findings. The owning agent (or Jose) decides the fix; this module never rewrites the downstream doc.
