# module: meeting-prep

> CUSTOMIZE: set the Meetings/ path, note-naming convention, and meeting-specific depth rules for your context.

Reusable capability. Preps every meeting **today + next ~72h**.

For each meeting:
- Append a **dated, frontmatter-tagged prep block** (`date / project / topics / people`) to the canonical per-person/meeting note in `Meetings/`. Create a per-person note only if none exists.
- Pull related issue-tracker items / email / Slack context + the last block's open action items; fill agenda + prep; **flag gaps** (unresolved items, decisions to raise, what to bring); confirm "ready?".
- **1:1s** get the most depth (extra-thorough).
- Durable **decisions** → promote to the relevant `Projects/<X>/Decisions/` ADR with a backlink (don't store in the meeting note).
- Surface action items into the brief's suggested actions. Never auto-create issue-tracker or calendar entries — drafts only.

<!-- CUSTOMIZE: list any standing meetings that need special prep logic (e.g., "Sprint planning: include velocity data", "Quarterly review: include metrics"). -->
