# module: inbox-triage

> CUSTOMIZE: update the mail search query, key-person list, and label names for your email setup.

Reusable capability. Read and organize only — **never send or delete.**

Search `in:inbox newer_than:2d` (or equivalent for your mail provider). Classify each thread:

- **Important** — from a key person, a comment on an active issue, a request/question/deadline, or an active project: **STAR** it + one-line "why + suggested action."
- **Noise (high-confidence only)** — automated notifications, no-reply senders, newsletters, duplicate calendar invites: label `LowPriority` + move out of inbox, then **list what moved and prompt the human to delete** (never delete yourself).
- **Unsure → leave in inbox and just flag.**

Output an Important / Noise block; fold actionable items into suggested actions.

<!-- CUSTOMIZE: list the senders/domains that should always be treated as Important or always as Noise for your context. -->
