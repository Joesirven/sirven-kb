# obsidian-kb

## Trigger

Use this skill whenever you are working inside an Obsidian vault and need to: find or reference information, add research papers or sources, create new documents, update existing ones, or maintain KB health. Trigger phrases include: "check the KB", "add this to research", "look up X in the vault", "document this", "add a paper", "populate the research folder", "update the knowledge base", "what does the KB say about", or any time the user is working inside a project that has a structured Obsidian vault.

Without this skill, agents tend to skip frontmatter, miss README updates, create files with wrong naming conventions, and do research sequentially when it should be parallelized.

## Core rules

### 1. Always read frontmatter schema first
Before creating or updating any document, read an existing file in the same folder to confirm the `---` frontmatter fields in use. Never invent new frontmatter keys mid-run. If the folder has no existing files, check the cluster README for the expected schema.

### 2. Update READMEs
After adding, renaming, or archiving any file, update the cluster README (the `README.md` or `agents.md` in the same folder) to reflect the change. README drift is the most common vault health failure.

### 3. Backlinks must be bidirectional
When you create a link from Document A to Document B, also add the corresponding backlink reference in Document B's frontmatter or body. One-way links cause orphan nodes and break navigation.

### 4. Naming convention
Use the naming convention already in use in the target folder. If in doubt, read three existing filenames in that folder before creating a new one. Do not invent a new convention mid-session.

### 5. Never modify locked or privileged documents
Some vaults designate certain documents as read-only or locked (e.g., legal, compliance, or policy files). Identify these before editing — check the folder README or any `locked:` frontmatter flag.

### 6. Scratch area for bulk operations
For any operation writing more than three new files, write to a scratch/tmp folder first. The lead agent (or user) reviews before promoting to permanent vault paths.

## When you are unsure

If you are unsure which folder a document belongs in, read the vault's top-level README or AGENTS.md to understand the folder structure and routing rules, then decide.

## Orchestration conventions (multi-agent / multi-step operations)

### Subagent coordination
Read your vault's subagent-orchestration module before spawning parallel agents for KB operations (index updates, staleness sweeps, batch document creation). Key rules:

- **Maker → Checker is mandatory.** Any subagent that creates or rewrites vault content (Maker) must have its output reviewed by the lead (Checker) before the change is committed to permanent paths. Checker verifies: correct frontmatter schema, README updated, backlinks bidirectional, no locked docs modified without authorization. Termination keyword: `APPROVED`.
- **Lead never idles.** While a batch of creation or retrieval agents runs, the lead should be reading related docs, pre-drafting the index update, or reviewing earlier results. Waiting passively for all subagents wastes context budget.
- **Non-overlapping file assignments.** Two agents must never edit the same file simultaneously. Assign explicit file-number or path ranges per agent at delegation time.
- **Write to scratch/tmp first for risky or bulk changes.** Agents writing many new docs should write to the scratch area and let the lead review before promoting to final vault paths.

### Decision log
Whenever a KB operation involves a convention choice, routing decision, or architectural change, record it as a keyed, append-only decision entry:

- Key format: inferred from context (e.g., `KBops-2026-06-08-staleness-threshold`).
- Record: what was decided, why, what alternatives were rejected, and `as_of` date.
- No status flags — currency is inferred from `as_of` date and entry order (latest wins).
- This applies to: cluster routing decisions, naming convention choices, staleness threshold changes, schema additions. Cosmetic fixes and typo corrections do not require a decision entry.

## Reference files

This skill references modules in your vault's `Ops/System/modules/` folder (or equivalent):
- `subagent-orchestration.md` — Maker/Checker rules, delegation prompt format
- `decision-log.md` — keyed entry schema

> Template note: this SKILL.md is intentionally generic. Customize frontmatter schema examples, folder routing rules, and locked-doc identification to match your vault's actual structure before rollout.
