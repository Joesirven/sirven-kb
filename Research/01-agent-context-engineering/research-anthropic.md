---
title: "Anthropic Agent Context, Memory & Retrieval — Doctrine + KB Implications"
type: research
status: research-complete
updated: 2026-06-06
topic_cluster: agent-context-engineering
source_url: "https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents"
source_type: docs
as_of: 2026-06-06
revisit_when: "2026-12-01 or when Anthropic publishes a new context-engineering post"
related:
  - "research-agentsmd.md"
  - "research-practitioners.md"
tags:
  - context-engineering
  - agents
  - memory
  - attention-budget
---

# Anthropic Agent Context, Memory & Retrieval: Doctrine + KB Implications

*Synthesized from primary Anthropic sources, June 2026*

---

## Part 1 — Core Principles (Anthropic Doctrine)

### P1. Context Is a Finite Resource With Diminishing Returns ("Attention Budget")

Every token added to the context window depletes an "attention budget." The transformer architecture creates n² pairwise relationships for n tokens; as context grows, the model's precision for retrieval and long-range reasoning degrades. This is called **context rot**: accuracy on needle-in-a-haystack retrieval measurably falls as total token count grows, across all models. The guiding engineering principle is therefore:

> **"Find the smallest possible set of high-signal tokens that maximize the likelihood of the desired outcome."**

*Source: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)*

### P2. Just-in-Time (JIT) Retrieval Over Pre-Loading

Rather than pre-loading all potentially relevant data, modern agentic design favors **JIT context**: agents maintain lightweight identifiers (file paths, queries, links) and load the actual content on demand via tools. Claude Code exemplifies this: CLAUDE.md files load up front; everything else (grep, glob, file reads) happens at runtime only when needed.

Benefits:
- Avoids stale indexing (pre-computed indexes go out of date; live file navigation does not)
- Bypasses complex syntax trees and embedding pipelines
- Mirrors human cognition (we use indexes and bookmarks, not memorized corpora)

*Source: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)*

### P3. Progressive Disclosure — Tiered Loading Based on Relevance

Context should load in tiers, from least to most specific, triggered by need:

| Level | What loads | When | Token cost |
|-------|-----------|------|------------|
| 1 | Name + description (metadata) | Always, at session start | ~100 tokens per item |
| 2 | Full instructions (SKILL.md body / agents.md body) | When agent determines it's relevant | <5k tokens |
| 3+ | Supporting files, scripts, schemas | Only when referenced during work | Effectively unbounded |

This design principle powers Agent Skills, CLAUDE.md hierarchies, and the memory tool. The system prompt should carry only enough signal for the agent to know *what* to load, not the full content of everything it might need.

*Sources: [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) · [Agent Skills docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)*

### P4. Structure and Naming Are Semantic Signals

Agents don't need explicit documentation for every decision. The environment itself provides signal:

> "To an agent operating in a file system, the presence of a file named `test_utils.py` in a `tests` folder implies a different purpose than a file with the same name in `src/core_logic/`. Folder hierarchies, naming conventions, and timestamps all provide important signals."

This means folder structure, file naming, and directory depth act as implicit retrieval cues — reducing the documentation burden on explicit instructions.

*Source: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)*

### P5. Instruction Count Has a Hard Ceiling (~150–200 for frontier models)

Research confirms that frontier thinking models can reliably follow approximately 150–200 instructions before attention degrades uniformly across *all* instructions (not just later ones). Claude Code's system prompt already consumes ~50 instructions — roughly a quarter to a third of that budget — before any agents.md is read.

Implications:
- A root agents.md with 100 lines of instructions is expensive
- Instructions should be universally applicable, not case-specific hotfixes
- Smaller/faster models degrade exponentially faster than frontier models

*Source: [Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) (citing empirical instruction-following research)*

### P6. System Prompts at the "Right Altitude"

System instructions fail at two extremes:
- **Too specific**: hardcoded if-else logic that is brittle and maintenance-heavy
- **Too vague**: high-level guidance that assumes shared context the model doesn't have

The target is *specific enough to guide behavior, flexible enough to provide strong heuristics*. Start minimal, test with the best available model, add only when failure modes are observed.

*Source: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)*

### P7. Memory = External File-Based Persistence Outside the Context Window

For long-horizon tasks or multi-session workflows, agents use **structured note-taking** — writing progress, decisions, and state to files outside the context window, then reading those back at the start of the next session. This is the mechanism behind:
- Claude Code's compaction + to-do lists
- The Memory Tool's `/memories` directory pattern
- The multi-agent research system's Memory writes before context overflow

The memory tool's system prompt instruction is: *"ALWAYS VIEW YOUR MEMORY DIRECTORY BEFORE DOING ANYTHING ELSE."* This forces deliberate context recovery at session start.

Status and progress should be **stored, not inferred**, because context resets happen without warning.

*Sources: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) · [Memory tool docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool)*

### P8. Sub-agent Architecture for Parallelism and Context Isolation

Each subagent gets a clean context window and works on a focused task. It can use tens of thousands of tokens internally but returns only a compressed summary (typically 1,000–2,000 tokens) to the orchestrator. This:
- Avoids context pollution in the lead agent
- Enables breadth-first parallel exploration
- Enables separation of concerns (distinct tools, prompts, trajectories per subagent)

Token usage explains 80% of performance variance; model choice and tool call count explain the rest.

*Source: [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)*

### P9. Tools Should Be Minimal, Non-Overlapping, and Self-Describing

Bloated tool sets create ambiguous decision points and waste the attention budget. If a human engineer can't definitively say which tool to use in a given situation, neither can the agent. Tool descriptions are as important as the tools themselves — a 40% improvement in task completion time was achieved solely by rewriting tool descriptions after automated test/failure analysis.

*Sources: [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) · [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)*

---

## Part 2 — Implications for Per-Directory agents.md in a Multi-Tool KB

*Context: A personal Obsidian vault (Catalist) operated by multiple agents across Cowork, Cursor, and Claude Code, governed by a cascade of agents.md files at each directory level.*

---

### I-1. CLAUDE.md / agents.md Loading Behavior Across Tools

**How it works in Claude Code**: At session start, Claude Code walks the directory tree upward and loads every CLAUDE.md it finds — global (`~/.claude/CLAUDE.md`), project root, and `CLAUDE.local.md`. Subdirectory CLAUDE.md files **lazy-load**: they are pulled into context only when Claude reads a file inside that subdirectory during a session. The cost of the hierarchy scales with what the agent is actually working on.

**Practical implication for agents.md**: The same pattern applies. Root-level agents.md loads every session. Child agents.md files should be treated as lazy-load documents — they earn their cost only when the agent enters that subtree.

**Cowork and Cursor**: These tools have their own loading behaviors (Cowork via skill system; Cursor via project rules). The shared principle is the same: root-level files are always-on tax, subdirectory files are on-demand.

*Source: [Subdirectory CLAUDE.md: Layered Context](https://claudefa.st/blog/guide/mechanics/subdirectory-claude-md) · [CLAUDE.md Lazy Loading](https://claude-wiki.com/claude-md-lazy-loading.html)*

---

### I-2. What Belongs in the ROOT agents.md

The root agents.md is pre-loaded every session by every tool. Every byte is a session-permanent token cost. Apply the strictest curation here.

**Include only:**
- **Vault identity**: One sentence — what this vault is and who it serves
- **Global navigation conventions**: How the KB is structured (top-level folder names and their purposes), so the agent can orient itself without reading anything else
- **Tool-specific routing**: Which agent tool (Claude Code / Cowork / Cursor) should handle which categories of work — prevents cross-tool context collisions
- **Cross-cutting constraints**: Permissions, naming conventions that apply everywhere (e.g., "never delete files without confirmation", "all new notes go to `_Inbox/`")
- **Pointers, not content**: References to child agents.md files with one-line descriptions — enabling progressive disclosure (the agent reads them only when entering those directories)

**Exclude from root:**
- Project-specific procedures, workflows, or statuses
- Code style guidelines (use linters)
- Any content that is not universally applicable across all sessions and all tools
- Historical context, changelogs, or explanations of past decisions
- Anything that can be inferred from folder structure and file naming alone

**Target length**: Under 60–80 lines. Root agents.md is the highest-leverage file in the vault; every line requires deliberate justification.

---

### I-3. What Belongs in CHILD agents.md (Per-Directory)

Child agents.md files are the JIT retrieval layer. They load only when an agent enters that subtree. This means they can be more detailed, but they must still pass the "universally applicable within this directory" test.

**Include:**
- **Directory purpose**: Two sentences on what this folder contains and when an agent should be working here
- **Naming / structure conventions** specific to this directory
- **Workflow steps** that are unique to this directory's content domain
- **Pointers to sub-files** the agent may need to load (schema files, reference docs, templates)
- **Status and memory notes** that persist state for this domain across sessions (updated by the agent)

**Exclude from child:**
- Content already covered by root agents.md (no duplication — duplication fragments attention)
- Cross-directory concerns that belong at root
- Verbose explanations that can be inferred from file names and folder structure

---

### I-4. Folder Structure and Naming AS Context

Per principle P4, the folder hierarchy is itself a retrieval signal. Corollaries for the KB:

- **Folder names should be self-explanatory without agents.md**: If an agent needs to read instructions to understand what `Ops/` vs `Projects/` contains, the naming has failed
- **Sub-folder depth signals scope**: `Projects/Active/` vs `Projects/Archive/` communicates current relevance without a word of instruction
- **File naming conventions reduce instruction burden**: `YYYY-MM-DD-topic.md` in `Meetings/` is self-describing; no agents.md entry needed to explain the pattern if the pattern is consistent
- **Sentinel files as retrieval hooks**: A `STATUS.md` or `PROGRESS.md` at directory root acts as a structured memory checkpoint the agent can find with a single `ls` — no embedding required

---

### I-5. Status and Memory: Stored, Not Inferred

Context resets happen without warning (compaction, session restart, tool switch). Status must be written to durable files, not kept only in conversation history.

**Pattern for the KB:**
- Each active project or domain directory should have a `STATUS.md` (or equivalent) that agents update at end-of-session with: current state, last action taken, next action needed, any blockers
- The root agents.md should instruct: "Before starting any work, read `STATUS.md` in the relevant directory"
- This mirrors the Memory Tool's "ALWAYS VIEW YOUR MEMORY DIRECTORY BEFORE DOING ANYTHING ELSE" protocol

**What NOT to put in agents.md for status**: Live status, current sprint, open tasks. These change frequently and will immediately make the agents.md file stale, causing it to become misinformation rather than signal.

---

### I-6. Context Rot Prevention Across Multiple Tools

Because Cowork, Cursor, and Claude Code each start fresh sessions, the vault will accumulate agents.md files that drift out of sync with reality. Mitigations:

1. **Pointers, not copies**: agents.md files should reference authoritative sources (a schema file, a README) rather than duplicating content that will go stale. "See `Projects/active-projects.md` for current project list" beats a hardcoded list.
2. **Date-stamp context**: Any agents.md entry that will age (e.g., current conventions, active integrations) should note when it was last verified
3. **Progressive disclosure for tool-specific behavior**: Rather than one monolithic root agents.md that tries to cover Cowork, Cursor, and Claude Code simultaneously, consider a pointer structure: root agents.md → `_meta/cowork-conventions.md`, `_meta/cursor-conventions.md`, `_meta/claude-code-conventions.md`. Each tool's agent loads only what's relevant.

---

### I-7. Multi-Tool Orchestration Pattern

Given sub-agent architecture (P8), the KB agents.md cascade maps naturally to orchestrator/worker roles:

- **Root agents.md** = orchestrator instructions: what this KB is, how it's organized, which tool handles which domain, where to find sub-instructions
- **Child agents.md** = worker instructions: scoped procedures for the specific subdomain this agent is exploring in this session
- **STATUS.md / memory files** = shared state that survives context resets and can be read by any tool

The lead tool (whichever is driving the session) reads root, navigates to the relevant subdirectory, loads the child agents.md JIT, reads STATUS.md for current state, then acts. On session end, it updates STATUS.md and any relevant memory files.

---

### I-8. Concrete Structural Anti-Patterns to Avoid

| Anti-pattern | Why it's harmful | Fix |
|---|---|---|
| Long root agents.md (>150 lines) | Consumes instruction budget before any work starts; degrades all instruction-following | Trim to universal-only; move domain content to child files |
| Status/progress in agents.md | Goes stale immediately; becomes misinformation | Move to STATUS.md, updated by agent |
| Duplicated content across root and child | Splits attention; root version likely stale | Use pointers; child adds, never duplicates |
| Tool-specific instructions mixed in root | Cowork reads Cursor instructions and vice versa | Split to `_meta/[tool]-conventions.md`, referenced by pointer |
| Naming conventions as prose in agents.md | Can be inferred from consistent folder/file naming | Trust the structure; document only the exceptions |
| Code style in agents.md | Stale, wastes budget, agents are bad linters | Use a linter + hook; remove from agents.md |

---

## Sources

1. [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic Engineering, Sep 2025
2. [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) — Anthropic Engineering, Dec 2024
3. [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — Anthropic Engineering, Jun 2025
4. [Memory tool documentation](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool) — Anthropic Developer Platform
5. [Agent Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) — Anthropic Developer Platform
6. [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — Anthropic Engineering, Oct 2025
7. [Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — HumanLayer, Nov 2025
8. [Subdirectory CLAUDE.md: Layered Context](https://claudefa.st/blog/guide/mechanics/subdirectory-claude-md) — ClaudeFast
9. [CLAUDE.md Lazy Loading](https://claude-wiki.com/claude-md-lazy-loading.html) — Claude Wiki
10. [Agent Skills: Progressive Disclosure as a System Design Pattern](https://www.newsletter.swirlai.com/p/agent-skills-progressive-disclosure) — SwirlAI Newsletter
