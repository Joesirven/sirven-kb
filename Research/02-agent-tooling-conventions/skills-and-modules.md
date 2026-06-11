---
title: "Skills and Modules — best practices for Claude/Cowork agent skills and their relationship to KB modules"
type: research
status: research-complete
updated: 2026-06-08
topic_cluster: agent-tooling-conventions
source_url: multiple (see Sources section)
source_type: docs | blog | x | industry
related:
  - per-tool-agent-files.md
tags:
  - skills
  - SKILL.md
  - progressive-disclosure
  - modules
  - obsidian-kb
  - deep-research
  - kb-audit
  - scheduling
  - instance-skills
  - capability-modules
---

# Skills and Modules — Best Practices

## TL;DR (read this; the rest is JIT)

1. **Progressive disclosure is the canonical architecture.** Anthropic's official model has three hard levels: Level 1 = YAML frontmatter metadata (~100 tokens, always loaded); Level 2 = SKILL.md body (<5k tokens, loaded on trigger); Level 3 = `references/` files + `scripts/` (effectively unlimited, loaded only when referenced). This is fully documented and production-proven.

2. **Thin skills pointing to modules is a real, named pattern.** The "modular skill system" pattern — thin SKILL.md that delegates to sub-files or sub-modules via explicit references — is confirmed by multiple independent practitioners (MindStudio, Bibek Poudel, Dr. Amit Ray, HatchWorks). The pattern is: SKILL.md stays under ~40 lines; deep content lives in `references/`; conditionals route to the right reference. This is the correct design for any skill that grows beyond ~200 lines.

3. **Scheduled/instance skills vs. capability skills must be separated.** HatchWorks (June 2026, citing Anthropic positioning) provides the clearest articulation: Skills = unit of capability; Scheduled Tasks / Routines = unit of autonomy. An "every-morning" skill is a trigger configuration wrapping a capability skill — it should not embed the capability logic itself. The two concerns belong in different layers.

4. **KB convention enforcement through skills is proven practice.** The Quevin/Davison Obsidian+Claude Code KB (March 2026) shows a live implementation: a `docs-organizer` subagent encodes the taxonomy, naming conventions, frontmatter schema, and categorization decision tree as executable instructions. Agent writes; human reviews. Convention drift is structurally prevented, not just warned about.

5. **The "thin wrappers with conditionals, passing parameters" hypothesis is VALIDATED** — but with a clarification: Claude is the coordinator, not the skill. Skills don't call each other directly. Claude reads each skill's output and routes to the next. The thin-wrapper pattern works by keeping SKILL.md minimal and letting `references/` files act as the routable sub-modules.

6. **Hacker News skepticism is a real signal, not noise.** A top HN comment (wg0, June 2026, 198-point thread) labels the entire skill-harness approach "snake oil" because LLMs cannot be relied on to follow hard requirements in markdown files. This is adversarially important: skills provide guidance and dramatically increase consistency, but they are not deterministic execution. Design accordingly — treat skills as high-probability instructions, not guaranteed contracts.

7. **The deep-research / obsidian-kb / kb-audit skill family** exemplifies the correct architecture: each skill is a thin entry point; heavy convention knowledge lives in `references/`; the skills coordinate via Claude's routing, not via direct calls between skills.

---

## Findings

### 1. Anatomy of a well-structured skill

Anthropic's engineering blog (Oct 2025, Zhang/Lazuka/Murag) and the official platform docs (platform.claude.com) define the canonical structure:

```
skill-name/
├── SKILL.md          # Required; frontmatter + body
├── references/       # Optional; loaded on demand at Level 3
│   ├── detailed-guide.md
│   └── edge-cases.md
├── scripts/          # Optional; executed via bash, never loaded into context
│   └── process.py
└── assets/           # Optional; templates, fonts, static resources
```

**Key loading facts (official, verified):**

| Level | When loaded | Token cost | Content |
|---|---|---|---|
| 1: Metadata | Always, at startup | ~100 tokens per skill | `name` + `description` YAML frontmatter only |
| 2: Instructions | On trigger match | <5k tokens | Full SKILL.md body |
| 3: References/scripts | On explicit reference or execution | Unlimited (not in context until accessed) | Any bundled file; scripts run without entering context |

The official API docs note a 140x efficiency difference between loading everything upfront vs. progressive disclosure. This is not marketing — it maps directly to real context window arithmetic.

**The description field is the single highest-leverage element.** Bibek Poudel (Medium, Feb 2026) documents this clearly: skills fail not because of the instructions but because the two-line frontmatter description fails to match trigger intent. The description must express both what the skill does AND when to use it, with specific trigger phrases covering all the ways a user might phrase that request.

### 2. Thin skills → modules/sub-skills pattern

This pattern is real and widely used. The clearest articulation is from the MindStudio modular skill system article (May 2026):

> "Client configs should be thin. If you're writing multi-line prompt logic in a client config, stop and move it into a named skill. The whole point of the library is that logic lives there."

The equivalent principle for individual skills: **if SKILL.md is getting long, split content into separate files and reference them.** From Anthropic's own engineering blog:

> "If certain contexts are mutually exclusive or rarely used together, keeping the paths separate will reduce the token usage."

The `code-reviewer` example from Poudel's guide is the clearest worked example of this: the SKILL.md body stays under 40 lines, containing the process steps. The detailed criteria live in `references/criteria.md` and are loaded only during an actual review. This is "thin SKILL.md referencing a module" implemented precisely.

**Conditionals and parameter passing:** Claude is the coordinator — it reads the SKILL.md body, sees a reference like `For form-filling, see [FORMS.md](FORMS.md)`, and makes the routing decision. The skill does not programmatically call a sub-skill; it provides structured guidance and Claude routes. MindStudio's chaining article (March 2026) confirms: "Claude evaluates the output of a skill and decides which path to take next. The chain isn't strictly linear — it can fork based on conditions."

**Branching example (confirmed pattern):**
```
check_code_quality → [if issues: run_linter → suggest_fixes]
                  → [if clean: run_tests → deploy]
```

**Important limitation flagged by GitHub issue #28266:** nested skills (a `skills/` subdirectory inside a skill containing its own SKILL.md files) are NOT recursively discovered by Claude Code. Only the parent SKILL.md is detected. The practical workaround is either symlinks or explicit references inside the parent SKILL.md.

### 3. Module inheritance and layering

The three-tier progressive disclosure maps directly to a module hierarchy:

- **Tier 1 (always available):** frontmatter metadata — equivalent to a module registry/index
- **Tier 2 (loaded on activation):** SKILL.md body — equivalent to the module's public API / main entry point
- **Tier 3 (loaded on demand):** `references/` files — equivalent to internal sub-modules, loaded only when the specific sub-capability is needed

The MindStudio modular system article describes a higher-level version of this for multi-client skill libraries: a `skills/` directory acts as a shared library, each client config is a thin wrapper specifying which skills to load plus client-specific overrides. This is "module inheritance" applied to skill composition.

**Wrapper scripts as module triggers** (confirmed): Skills can include a `scripts/` directory with Python or shell scripts. Claude runs these via bash. The scripts' code never enters the context window — only their output does. This is the correct pattern for deterministic operations that shouldn't burn tokens.

### 4. Instance-based skills vs. capability modules

This is the most important architectural separation that practitioners get wrong.

**HatchWorks (Andy Smith, June 2026)** provides the clearest framework, citing Anthropic's own product framing:

> "Everything earlier in the series (Skills, sub-agents, the SDK) makes the agent capable. The two products (Scheduled Tasks and Routines) are what make the agent autonomous, on a controlled cadence."

The separation is architectural:

| Layer | What it is | Examples |
|---|---|---|
| **Capability skill** | What the agent knows how to do | `deep-research`, `obsidian-kb`, `kb-audit` |
| **Trigger / Instance** | When and why the agent runs | Scheduled Task ("every Monday"), Routine (on PR event), API webhook |

An "every-morning briefing" is a **Scheduled Task that invokes capability skills** — it is not a capability skill with scheduling logic baked in. Mixing trigger logic into a capability skill creates a skill that can't be used on-demand, can't be composed into other workflows, and can't be tested in isolation.

**Claude Code Routines** (research preview, 2026) support three trigger types on a single configuration: schedule (hourly/daily/weekly), API webhook (HTTP POST with context payload), and GitHub event (PR opened, release created). These can be stacked — the same capability can be triggered by a schedule AND a webhook AND a GitHub event.

**Cowork Scheduled Tasks** (April 2026) are simpler: a saved Cowork prompt running on a cadence (hourly/daily/weekday/weekly/manual), requiring the desktop app to be open. Best for knowledge work, not production systems.

**Karo Zieminski (Substack, March 2026)** confirms from practitioner experience: "Skills in Cowork are operational. They shape autonomous work. Your brand guidelines skill doesn't just influence a reply. It governs every file Claude creates." The skill is the capability; the schedule is the trigger. Keep them separate.

### 5. Enforcing KB conventions through skills

**Validated pattern from production:** Kevin Davison (Quevin.com, March 2026) documents a complete implementation where a `docs-organizer` Claude Code subagent encodes:
- Type-first taxonomy (12 document categories, each with a prefix: JIRA, DOC, CR, ASM, INC, RB, SW)
- Naming conventions (prefix-slug-date.md pattern)
- Frontmatter schema (title, prefix, category, author, date, status, tags — all required)
- Categorization decision tree (priority-ordered: P0/P1 bugs first, then blockers, then features, etc.)
- Controlled tag vocabulary (enumerated in agent instructions)

The result: "inconsistent note formats break everything downstream — Dataview queries fail and the agent gets confused about where to find information." The skill prevents this by being the only path through which files are created or renamed.

**Key design principle from this implementation:**
> "The agent definition is the most important piece. It encodes your information architecture as executable instructions. Get this right and the system runs itself."

**For Obsidian-specific enforcement**, the Karpathy-style KB gist (referenced in search results) shows a `vault_lint.py` script bundled in a skill's `scripts/` directory, checking:
- naming conventions
- frontmatter completeness  
- status↔location consistency
- broken backlinks
- stale dates

Running this script via the skill's bash tooling (not loading it into context) is the correct pattern for linting-type enforcement.

**Anti-drift strategies (synthesized from sources):**

1. **Structural prevention:** The docs-organizer pattern — convention is enforced at write time, not audited after the fact.
2. **Periodic audit skills:** `kb-audit` as a separate scheduled skill that runs a linter and reports drift. Separation of concerns: the capability skill enforces; the audit skill monitors.
3. **Status field + location contract:** A `status` frontmatter field (draft | active | stale | archived) that determines which folder the file lives in. An agent that moves files checks this field — drift means status↔location mismatch.
4. **README as cluster contract:** Each cluster has a README that defines what belongs there. An audit skill checks every file against the README's stated scope.

### 6. The deep-research / obsidian-kb / kb-audit family as an example

These three skills represent the correct architecture applied to a real skill family:

**deep-research:** Thin trigger SKILL.md (describes when to use it — research topics). The heavy methodology (fan-out search, source fetching, adversarial verification, synthesis routing) lives in the references. The `05-RESEARCH` and `PAPER-TEMPLATE.md` conventions are referenced, not duplicated in the SKILL.md body.

**obsidian-kb:** Thin trigger SKILL.md (describes when to use it — vault operations). KB conventions (naming, frontmatter, README updates, lean-access) live in references. The skill prevents agents from operating on the vault without loading the conventions first.

**kb-audit:** Instance-like capability — it runs periodically. The audit logic (broken backlinks, frontmatter hygiene, orphan files, stale docs, interrupted deep-research runs) should be modular: each check could be its own `references/check-*.md` file loaded only when the relevant check is requested.

**Correct relationship between the three:**
```
deep-research  →  writes to 05-RESEARCH (following PAPER-TEMPLATE)
obsidian-kb    →  reads/edits vault files (enforcing KB conventions)
kb-audit       →  scans vault health (reporting to 00-KB-AUDIT.md)
```
They coordinate through shared file conventions, not by calling each other directly. Claude routes between them based on task context.

---

## How to apply this to our skills (deep-research v2, obsidian-kb, kb-audit)

### Immediate changes

**1. Audit and trim SKILL.md bodies.** Any skill whose SKILL.md body exceeds ~150 lines has a structural problem. Move edge-case handling, detailed examples, and sub-workflow specifications into `references/` files with descriptive names. Reference them explicitly from the SKILL.md body with conditional language ("For multi-wave fan-out, see [references/fan-out-protocol.md]"). This is the single highest-ROI change — it keeps Level 2 token cost low while preserving Level 3 depth.

**2. Split the deep-research skill into capability + schedule.** If deep-research is being used both on-demand (triggered by user request) and on a schedule (e.g., periodic KB population), the scheduling configuration should be a separate Scheduled Task or Routine that calls the deep-research capability. The deep-research SKILL.md should contain no scheduling logic.

**3. Harden obsidian-kb convention enforcement.** The obsidian-kb skill should have a `references/kb-conventions.md` file that is the single source of truth for naming, frontmatter schema, folder structure, and lean-access rules. Every other place that references these conventions should point here. The skill's SKILL.md body should reference this file explicitly so it's loaded on every vault operation — not just when the agent happens to recall it.

**4. Give kb-audit a modular check structure.** Move each audit check into a separate `references/check-*.md` file:
- `references/check-broken-backlinks.md`
- `references/check-frontmatter-hygiene.md`
- `references/check-orphan-files.md`
- `references/check-readme-drift.md`
- `references/check-interrupted-research.md`

The SKILL.md body routes to the relevant checks based on what the user requests. Running a full audit loads all of them; running a targeted check loads only one. This makes kb-audit composable and keeps individual runs lean.

### Medium-term (next sprint)

**5. Formalize the skill↔module boundary in AGENTS.md.** Add a section to the KB's AGENTS.md (or relevant CLAUDE.md) that defines: (a) which skills exist and their trigger phrases, (b) which reference files each skill loads, (c) the convention that skills do not call each other directly — Claude routes. This prevents future drift where a skill tries to invoke another skill programmatically.

**6. Add `allowed-tools` to read-only skills.** kb-audit should be constrained with `allowed-tools: Read, Grep, Glob` so it cannot accidentally modify files during an audit run. This is documented as experimental but well-supported in Claude Code as of early 2026.

### Verification / de-risking (the HN skepticism point)

The wg0 HN comment is worth operationalizing: **treat all skill instructions as high-probability guidance, not guaranteed execution.** Specifically:

- Design skills so that the "wrong" path is safe (e.g., kb-audit that misses a check is annoying but not destructive; a docs-organizer that miscategorizes a file is recoverable).
- For irreversible operations (deleting, archiving, publishing), require explicit human confirmation inside the skill instructions AND in any Routine/Scheduled Task that wraps the capability.
- Use the "validator before worker" pattern for high-stakes operations: deep-research should produce a draft synthesis for human review before routing to the KB, not write directly to the KB in a single step.

---

## Source quality assessment

| Source | Type | Quality signal | Hype flag |
|---|---|---|---|
| Anthropic engineering blog (Zhang/Lazuka/Murag, Oct 2025) | Official | Primary, authoritative | None |
| platform.claude.com docs (agent-skills/overview, best-practices) | Official | Primary, authoritative | None |
| HatchWorks (Andy Smith, June 2026) | Industry blog | High — cites Anthropic product framing, multi-article series | Low |
| Bibek Poudel (Medium, Feb 2026) | Practitioner | High — worked examples, verified against official docs | Low |
| MindStudio (May 2026, modular skill system) | Vendor blog | Medium — accurate architecture, self-promotional | Medium (vendor) |
| Karo Zieminski (Substack, March 2026) | Practitioner | High — 56 tested tips, honest about failures | Low |
| Kevin Davison/Quevin (March 2026) | Practitioner | High — real production implementation, specific numbers | Low |
| Marta Fernández García (Medium, Feb 2026) | Practitioner | Medium — accurate but brief | Low |
| HN wg0 comment (June 2026) | Community skeptic | High — adversarial signal, valid critique | N/A (skeptic) |
| GitHub issue #28266 (anthropics/claude-code) | Bug report | High — factual, filed against official repo | None |

**Hype vs. proven:**
- Progressive disclosure (3-level loading): **proven** — official docs, engineering blog, multiple independent confirmations
- Thin skill → module pattern: **proven** — multiple independent implementations
- Scheduled vs. capability separation: **proven** — Anthropic's own product architecture enforces it
- KB convention enforcement via skills: **proven** — Davison implementation with 77+ files and 6 months of data
- "Skills guarantee execution": **hype / false** — HN wg0 is correct; skills are high-probability guidance, not deterministic

---

## Sources

- [Equipping agents for the real world with Agent Skills — Anthropic Engineering Blog](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) (Oct 2025, Zhang/Lazuka/Murag)
- [Agent Skills Overview — Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) (platform.claude.com)
- [Skill authoring best practices — Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) (platform.claude.com)
- [Building Agents with Claude: From Skills to Scheduled Tasks and Routines — HatchWorks](https://hatchworks.com/blog/claude/building-agents-with-claude/) (Andy Smith, June 2026)
- [The SKILL.md Pattern: How to Write AI Agent Skills That Actually Work — Medium](https://bibek-poudel.medium.com/the-skill-md-pattern-how-to-write-ai-agent-skills-that-actually-work-72a3169dd7ee) (Bibek Poudel, Feb 2026)
- [How to Build a Modular Skill System in Claude Code That Scales Across Clients — MindStudio](https://www.mindstudio.ai/blog/modular-skill-system-claude-code-multi-client) (May 2026)
- [What Is Claude Code's Skill Collaboration Pattern? — MindStudio](https://www.mindstudio.ai/blog/claude-code-skill-collaboration-pattern) (March 2026)
- [Claude Cowork Guide for Power Users — Substack](https://karozieminski.substack.com/p/claude-cowork-guide-plugins-memory-sub-agents-tips) (Karo Zieminski, March 2026)
- [How I Turned My Git Repo Into a Self-Organizing Knowledge Base With Obsidian and an AI Agent — Quevin](https://www.quevin.com/blog/2026-03-27-obsidian-agent-knowledge-base) (Kevin Davison, March 2026)
- [Progressive Disclosure: the technique that helps control context (and tokens) in AI agents — Medium](https://medium.com/@martia_es/progressive-disclosure-the-technique-that-helps-control-context-and-tokens-in-ai-agents-8d6108b09289) (Marta Fernández García, Feb 2026)
- [Agent Skills — Hacker News thread](https://news.ycombinator.com/item?id=48015397) (June 2026, 198 points, 86 comments — wg0 skeptic comment)
- [Skills: nested skills in skills/*/SKILL.md not discovered — GitHub Issue #28266](https://github.com/anthropics/claude-code/issues/28266) (anthropics/claude-code)
- [Claude Code Skills vs Agents vs Workflows: The Three-Tier Hierarchy — Dr. Amit Ray](https://amitray.com/claude-code-skills-vs-agents-vs-workflows/) (May 2026)
- [A Mental Model for Claude Code: Skills, Subagents, and Plugins — Level Up Coding](https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05) (Dean Blank)
- [Progressive Disclosure in AI Agents — MindStudio](https://www.mindstudio.ai/blog/progressive-disclosure-ai-agents-context-management)
