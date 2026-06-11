# module: decision-log

**Scope:** canonical convention for append-only, keyed decision records across all vault areas.

## Per-area log file
Each area that makes durable decisions keeps a `decisions.md` at its root. It is append-only; entries are never edited in place.

## Entry format
```
### <ISO date> — <decision-key>
- **Decision:** <what was decided>
- **Why:** <terse rationale>
- **Implemented in:** <agents.md section / skill / module / code path>
- **Supersedes:** <prior entry date for same key, or —>
```

## Currency rule (no status fields)
The **current** decision for a key = the most recent entry bearing that key. All older entries for the same key = history/rationale. Never treat an older entry as canonical. Never add a "status: superseded" field — recency alone determines currency.

## Partial supersession
To change one decision without disturbing others: append a new entry for that key only. Other keys are untouched. Write decisions at the granularity of an independently-supersedable unit (one key per atomic decision).

## ADR overflow
If the rationale is long, create `decisions/<key>.md` and link it from the log entry. The log entry remains the currency record; the ADR file is rationale storage only.

## Compaction / split
When a `decisions.md` exceeds ~400 lines:
1. Identify "dead keys" — keys that have at least one newer entry (i.e., not the most recent entry for that key).
2. Move all dead-key entries into `decisions-archive-YYYY.md` (year = current year).
3. The live `decisions.md` then holds ≤ 1 entry per key = the current-state projection.
