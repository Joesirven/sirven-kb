# deep-research

## Trigger

Use this skill when the user asks to **research a topic**, **add sources**, **populate the knowledge base on a subject**, **do a deep dive**, or when a research question requires more than three sources. Also trigger when the user says "fill in research gaps", "update a topic cluster", or "give me a cited synthesis on [topic]".

## What it does

Implements a multi-phase fan-out research architecture:

- **Phase 1 — Plan.** Decompose the query into sub-questions. Define a source target (50–200 sources across two waves). Identify the correct destination layer in the KB (legal, business, product, or a project-specific folder — adapt to your vault structure).
- **Phase 2 — Wave 1 fetch (parallel).** Spawn parallel fetch agents, each scoped to non-overlapping source sets. Each agent writes verbatim source files to the designated scratch/tmp area. Scope boundaries must be explicit; include an `out-of-scope:` line in each agent's delegation prompt.
- **Phase 3 — Maker → Checker review.** Lead agent reviews Wave 1 artifacts against the Phase 1 plan. Gaps or errors are re-delegated with specific corrective instructions (max 2 retries per agent). Emit `APPROVED` when wave passes.
- **Phase 4 — Wave 2 fetch (gap-fill).** Run a second parallel wave targeting uncovered sources or angles identified in Phase 3.
- **Phase 5 — Synthesis.** Write a synthesis document backed by real citations. Route to the correct KB layer. Record any convention choices or architectural conclusions as decision-log entries (see § Orchestration conventions below).
- **Phase 5b — Decision log.** Any research finding that shapes a workflow, convention, or architectural choice becomes a keyed, append-only decision entry in the project decision log. See your vault's decision-log module for the schema.

## Orchestration conventions

### Subagent coordination
Read your vault's subagent-orchestration module before spawning any parallel fetch agents. Key rules:

- Maker → Checker is mandatory. Every fetch wave (Maker) must be reviewed by the lead (Checker) before synthesis proceeds.
- Lead never idles during a wave. Update the cluster README, pre-draft the synthesis outline, or review earlier wave output while agents run.
- Scope boundaries are explicit. Each agent's prompt includes an `out-of-scope:` line naming what other agents cover.
- Output to scratch/tmp first. Agents write intermediate work to a scratch area. Only the lead promotes reviewed artifacts to permanent KB paths.

### Decision log
Any research conclusion that shapes a workflow, convention, or architectural choice must be recorded as a keyed, append-only decision entry. Entry format: what was decided, why (citing the specific finding), what was rejected and why, and an `as_of` date. Do not use status flags — currency is inferred from position and `as_of` date.

## Source file format

Each fetched source should follow your vault's paper/source template (typically: title, url, date, summary, key quotes, relevance). Adapt to the template present in your vault's Research folder.

## Output locations

Adapt these to your vault structure:
- Source files → `Research/<topic-cluster>/` (or equivalent scratch area during the run)
- Synthesis document → the appropriate KB layer for the topic domain
- Decision entries → your project's decision log

## Quality gates

- Minimum source count met before synthesis starts (set per-run in Phase 1 plan).
- No source file contains fabricated quotes — verbatim only.
- Synthesis document cites specific source files by filename or anchor, not just URLs.
- All sub-questions from Phase 1 are addressed or explicitly marked out-of-scope.

## Reference files

This skill references modules in your vault's `Ops/System/modules/` folder (or equivalent):
- `subagent-orchestration.md` — Maker/Checker rules, delegation prompt format
- `decision-log.md` — keyed entry schema

> Template note: this SKILL.md is intentionally generic. Customize the output paths, source template reference, and KB layer names to match your vault's folder structure before rollout.
