# 01-PERSONAS

The universal persona roster for this base. Every fork of this base inherits these sixteen
personas; a fork may add its own tenant-specific personas alongside them (proven pattern:
the legal-agent repository's `01-PERSONAS/` directory, which adds a domain-specific
citations-verifier persona next to a generic set).

Design rationale, the full roster description, and why the roster is shaped this way live in
`agent-persona-model.md` (the Jefferson vault's Meadow-platform section) — that document is
the source of truth for *why*; the files here are the *contracts* each persona must satisfy
in this base.

## The contract shape

Every persona file in this directory is a four-part contract:

1. **Mandate** — what the persona is for (labeled "Mandate", "Role", or "Mission").
2. **Write scope** — an explicit allowlist of what it may write, if anything. Several
   personas here — the research personas and every reviewer — are read-only; their write
   scope says so explicitly ("none outside a scratch path").
3. **Definition of done** — when the persona's output is actually finished, not just
   attempted.
4. **Never** — concrete things this persona must never do.

## The roster

**Research (read-only):** `repo-researcher`, `web-researcher`, `deep-researcher`,
`last30days`.

**Planning and execution (planner runs first, then executor):** `planner`, `executor`,
`migrator` (a specialized executor for repository moves, reconciliation, and convention
migration).

**Review (read-only; which ones run depends on what the change touches):**
`convention-reviewer`, `correctness-reviewer`, `data-safety-reviewer`,
`maintainability-reviewer`, `security-reviewer`.

**Devil's advocate:** `adversarial-challenger`.

**Evaluation:** `test-author`, `judge`.

**Orchestration:** `orchestrator` — owns git and integration, dispatches the others, never
writes tenant content itself.

## How personas are found and enforced

Cascade-discovered, not registered in a lookup table: when an agent is dispatched into a
tenant's own tree, it reads that tenant's `agents.md` cascade — including that tenant's own
`01-PERSONAS/` (or `01-personas/`) directory — so the tenant's personas become available
alongside this universal set, automatically. A tenant may also declare, in its own
definition of done, that a change in some domain requires a specific domain reviewer; that
requirement is then enforced the same way the universal reviewers are.
