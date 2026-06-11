# module: meeting-ingestion

> CUSTOMIZE: set the Meetings/ path and canonical note-naming convention for your team.

Reusable capability: turn a meeting that **happened** into structured, durable knowledge + actions. Callable standalone (right after a meeting) or invoked by the daily/weekly retro.

## Trigger decision
- **On demand (preferred):** call this right after a meeting — recall is freshest, action items are accurate. Best for 1:1s and stakeholder meetings.
- **Daily backstop:** the afternoon retro runs this for every ended meeting on today's calendar that wasn't already ingested. If raw notes exist in the meeting's note → ingest. If the meeting ended with no raw notes → prompt the human to add them (don't fabricate). **Idempotent** — check for an already-ingested block and skip.
- **Weekly sweep:** catch any still-uningested meetings from the week.

## Steps
1. Identify the meeting (calendar event + the canonical per-person note in `Meetings/`).
2. From the human's raw notes, produce a **dated, frontmatter-tagged block** appended to that person's canonical note (see `Meetings/agents.md` for the standard block format). Never spawn a second note for a person who already has one.
3. Extract: **Decisions** (durable → flag for promotion to `Projects/<X>/Decisions/` ADR with backlink), **Action items** (→ surface into suggested tasks), **Open threads** (carry forward to next prep).
4. **Tickets:** draft any issue-tracker tickets to `tmp/issue-drafts/` and flag for approval (never auto-create) — see `jira-draft.md`.
5. If the meeting referenced a `Docs/` reference doc that may be outdated, trigger a staleness check (subagent) per `Docs/agents.md`.

## Output
The updated per-person note block + a 3-line summary (decisions / actions / anything needing human review) + any drafted ticket paths.
