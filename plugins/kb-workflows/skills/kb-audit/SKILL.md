# kb-audit

## Trigger

Use this skill when the user says "audit the KB", "check KB health", "find stale docs", "clean up the KB", "archive old stuff", "find orphan files", "what's broken in the vault", or asks to resume an interrupted research run.

This skill complements the obsidian-kb skill's reactive staleness propagation (use obsidian-kb for after-each-edit propagation; use this skill for periodic sweeps).

## What it does

Runs a parallel health sweep across seven concern areas. Appends findings to the vault's main audit log (e.g., `00-KB-AUDIT.md` or equivalent). Routes archive candidates to the designated archive folder.

## Phases

### Phase 1 — Load prior audit state
Read the existing audit log to identify open items from previous runs. Pre-build the report skeleton before launching check agents.

### Phase 2 — Parallel health checks (spawn concurrently)

Each check agent covers a non-overlapping concern:

1. **Broken backlinks** — find `[[wikilinks]]` or markdown links pointing to non-existent files.
2. **Frontmatter hygiene** — find files missing required frontmatter keys, using undocumented `status:` values, or with malformed date fields.
3. **Orphan files** — find files with no inbound links and no README reference.
4. **README drift** — find cluster READMEs that list files that no longer exist, or folders with files not listed in the README.
5. **Interrupted research runs** — find `tmp/` or scratch artifacts that were never promoted to permanent paths; emit a copy-pasteable resume recipe for each.
6. **Locked-doc dependency drift** — find documents that reference locked/legal/policy files; flag references to locked files that have been superseded or renamed.
7. **Archive candidates** — find files with stale `as_of` dates, deprecated status, or that are referenced only from already-archived documents.

### Phase 3 — Maker → Checker aggregation
Lead agent reviews each check agent's findings before writing to the audit log. Do not let a check agent write directly to the audit log — the lead aggregates and deduplicates. Termination keyword: `APPROVED` (lead emits this per check when findings are verified).

### Phase 4 — Auto-fix (low-risk only)
Apply auto-fixes only for low-risk items: remove dead links to deleted files, update README tables with correct filenames. All other findings are reported, not auto-fixed.

### Phase 5 — Archive moves
Move confirmed archive candidates to `06-ARCHIVE/` or `_archived/` (use the convention already present in your vault). Update all inbound links before moving.

### Phase 6 — Interrupted research resume
For each interrupted run found in Phase 2, emit a recipe block:
```
Resume recipe for: <topic>
  Last completed phase: <phase>
  Remaining phases: <list>
  Command: <copy-pasteable prompt to resume>
```
Do NOT invoke deep-research automatically — emit the recipe only.

### Phase 6b — Orchestration conventions

#### Subagent coordination
Read your vault's subagent-orchestration module before spawning parallel check agents. Key rules:

- **Maker → Checker is mandatory for reconcile mode.** Audit check agents (Makers) return structured findings. The lead (Checker) reviews each finding before applying any auto-fix and before appending to the audit log. Do not let a check agent write directly to the audit log.
- **Lead never idles.** While parallel check agents run (Phase 2), the lead should be reading the prior audit log, pre-building the report skeleton, or triaging already-returned findings.
- **Scope assignments prevent double-reporting.** Each check agent covers a non-overlapping concern. If a finding could belong to two checks, assign it to the higher-severity check. Do not report the same file twice.

#### Decision log
Audit findings that reveal a convention gap — not a broken file, but a missing or ambiguous convention — should be recorded as a keyed, append-only decision entry:

- Key format: inferred from context (e.g., `AUDIT-2026-06-08-archive-destination-ambiguity`).
- Record: what the audit found, what convention was missing or conflicting, the chosen resolution, and `as_of` date.
- No status flags — currency is inferred from `as_of` date and entry order.
- Examples that warrant a decision entry: two competing archive destinations with no clear rule; an undocumented `status:` value found in active use; README drift revealing a cluster has grown beyond its documented scope.
- Routine findings (broken backlinks, stale dates, orphan files) go only to the audit log, not to the decision log.

## Quality gates

- All seven check concerns were run (or explicitly skipped with reason noted).
- No auto-fix was applied without lead-agent review.
- Audit log entry is append-only — prior entries are not modified.
- Every archive move has inbound links updated before the file is moved.

## Reference files

This skill references modules in your vault's `Ops/System/modules/` folder (or equivalent):
- `subagent-orchestration.md` — Maker/Checker rules, delegation prompt format
- `decision-log.md` — keyed entry schema

> Template note: this SKILL.md is intentionally generic. Customize the audit log filename, archive destination folder, and check-agent scope boundaries to match your vault's actual structure before rollout.
