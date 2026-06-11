# sirven-kb

Personal agent knowledge base. A structured Obsidian vault + Claude Code KB built on the conventions in Part 2 below. Designed to be inherited by any personal or project-scoped KB.

This README is the single entry point: **Part 1** is operational setup, **Part 2** is the design rationale (read before changing any convention), **Part 3** is the sourced research digest. For *how to edit safely*, see [`_meta/CONTRIBUTING.md`](_meta/CONTRIBUTING.md).

---

## What this repo is

`sirven-kb` is an **opinionated personal KB skeleton** providing:

- Root and per-area `AGENTS.md` / `README.md` templates with the cascade convention baked in.
- Cross-cutting modules (`Ops/System/modules/`) any fork can use unmodified or extend.
- A `Research/PAPER-TEMPLATE.md` for structured source cards.
- A plugin marketplace manifest (`.claude-plugin/marketplace.json`) with skills + a forced-eval hook.

---

# Part 1 — Setup

## 1. Clone

```bash
git clone git@github.com:Joesirven/sirven-kb.git
cd sirven-kb
```

To use this as a base for a new KB, fork and add it as upstream:

```bash
git remote add upstream git@github.com:Joesirven/sirven-kb.git
```

## 2. Wire it into Claude Code

Add to `~/.claude/CLAUDE.md`:

```markdown
@~/path/to/sirven-kb/AGENTS.md

## Personal preferences
# Machine-local overrides here — never commit this file.
```

The `@` import loads the KB's root `AGENTS.md` into every session on this machine.

**Scope layers:**
- `/etc/claude-code/CLAUDE.md` — org-wide managed policy (MDM/Ansible); cannot be excluded.
- `~/.claude/CLAUDE.md` — user scope; personal preferences and KB import.
- `./CLAUDE.md` / `./.claude/CLAUDE.md` — project scope; committed, team-shared.

## 3. Plugin marketplace (skills)

```bash
/plugin marketplace add git@github.com:Joesirven/sirven-kb.git
/plugin install kb-workflows@sirven-kb
```

Zero-friction onboarding — commit to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "sirven-kb": { "source": { "source": "git", "url": "git@github.com:Joesirven/sirven-kb.git" } }
  },
  "enabledPlugins": { "kb-workflows@sirven-kb": true }
}
```

## 4. Versioning

- **Patch** (`v1.0.x`): clarifications, backward-compatible module additions.
- **Minor** (`v1.x.0`): new module / skill / area template.
- **Major** (`vX.0.0`): breaking changes to cascade conventions or module interfaces.

`CHANGELOG.md` is append-only; one entry per tag.

---

# Part 2 — Design rationale

> Read before changing any convention. Each entry: the decision, why it exists, and what breaks if ignored.

## R1. AGENTS.md cascade + lean size limits
**Decision:** every directory has its own `agents.md` carrying only local rules; a root `AGENTS.md` cascades into children. Children ≤ ~80 lines, root ≤ ~45.
**Why:** context files compete for a finite attention budget — Claude Code's system prompt already uses ~50 of ~150–200 reliable instruction slots; adherence degrades non-linearly past ~200 lines, and Codex CLI *silently truncates* past 64 KiB. The cascade is progressive disclosure: each level loads only its local rules.
**What breaks:** a bloated `agents.md` should extract content into a module + pointer; a root past ~45 lines should use the router pattern, not grow.

## R2. Modules over duplication + `> inherits:` layering
**Decision:** vault-wide capability logic lives in `Ops/System/modules/`; skills are thin wrappers; modules may inherit others via `> inherits: <path>`.
**Why:** without a module layer, every skill/task duplicates logic, and when it changes some copies are missed. One module edit propagates everywhere.
**What breaks:** adding logic into a skill rather than a module guarantees the next skill duplicates it.

## R3. Decision-log: inferred currency, no status fields
**Decision:** current decision for a key = the most recent entry for that key in `decisions.md`; older entries are history only; never store `status: active/superseded`.
**Why:** status fields lie — when an entry is superseded, someone must remember to mark the old one, and that step gets skipped. Recency-as-currency is self-maintaining.
**What breaks:** never add status fields; to update a decision, append a new keyed entry.

## R4. Subagent maker→checker orchestration
**Decision:** non-trivial work uses a game-master + specialist subagents; every subagent output is checked before use; subagents write to `tmp/` and return paths; parallel agents own disjoint file sets (or worktrees).
**Why:** a single-agent loop compounds errors with no correction surface. The maker→checker split adds a review boundary. Anthropic's production Research system beat single-agent Opus by 90.2%; subagents act as context garbage collectors.
**What breaks:** don't spawn inline and paste output into the thread; use `tmp/`. The checker step is not optional for tasks that modify permanent files.

## R5. Personal base split
**Decision:** shared/generic conventions live here; personal content (goals, private notes, credentials, project-specific knowledge) stays gitignored or in `~/.claude/CLAUDE.md`.
**Why:** a committed file referencing a personal path leaks the vault's existence and fails on other machines. The two trees stay independent.
**What breaks:** reject any commit adding personal paths, credentials, or machine-specific content.

## R6. Skills ship via plugin marketplace + forced-eval hook
**Decision:** skills travel via `.claude-plugin/marketplace.json`; a forced-eval hook ships as the first skill.
**Why:** committing `.claude/skills/` makes source visible but installs nothing. The marketplace is the only path from "committed" to "installed + active." The forced-eval hook fixes unreliable activation: 84% trigger with it vs. 20% without (Scott Spence production measurement).
**What breaks:** dropping a `SKILL.md` into `.claude/skills/` makes it available to no one. Add it under `plugins/<plugin>/skills/`, register in `marketplace.json`, bump the version.

---

# Part 3 — Research digest (sources)

> Condensed, sourced findings behind the conventions above. Full source cards in `Research/`.

**Context engineering / attention budget.** Instruction files compete for a finite budget; past ~200 lines adherence degrades non-linearly; Codex CLI silently truncates past 64 KiB. ETH Zurich AGENTbench (arXiv 2602.11988, Feb 2026, 138 tasks): LLM-generated context files **−3%** task success (+20% cost); human-written **+4%**. Progressive disclosure yields ~140x efficiency difference (Anthropic, "Equipping agents with Agent Skills", Oct 2025).

**Per-tool files (AGENTS.md / CLAUDE.md).** AGENTS.md is the cross-tool open standard (60k+ repos); Claude Code reads CLAUDE.md **only** — the "AGENTS.md fallback" is false (GH issue #6235). Correct pattern: AGENTS.md as source of truth + `@AGENTS.md` as CLAUDE.md's first line.

**Modules vs duplication.** Thin SKILL.md → module pattern validated independently (Bibek Poudel, Feb 2026; MindStudio, May 2026). `> inherits:` mirrors class inheritance. One-edit-propagates prevents drift.

**Decision-log / ADR staleness.** Status fields drift; recency-as-currency is self-maintaining. Append-only keyed log; dead-key compaction at ~400 lines.

**Subagent orchestration.** Lead + specialist subagents beat single-agent Opus by 90.2% (Anthropic Research system). Spawn break-even ~10k input tokens of real work. Git worktrees isolate parallel agents.

**Skill sharing.** `.claude/skills/` committed = source visible, nothing installed. Marketplace = git repo + `.claude-plugin/marketplace.json`; install via `/plugin marketplace add` + `/plugin install`. Forced-eval hook: 84% vs 20% activation (Scott Spence, Jan 24 2026).
