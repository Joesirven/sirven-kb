---
title: "Practitioner Discourse — AI Agent Context, Retrieval & Knowledge Bases"
type: research
status: research-complete
updated: 2026-06-06
topic_cluster: agent-context-engineering
source_url: "https://www.trychroma.com/research/context-rot"
source_type: blog
as_of: 2026-06-06
revisit_when: "2026-12-01 or when a new Chroma context-rot benchmark drops"
related:
  - "research-anthropic.md"
  - "research-agentsmd.md"
tags:
  - context-rot
  - JIT-retrieval
  - practitioners
  - KB-patterns
---

# Practitioner Discourse: AI Agent Context, Retrieval & Knowledge Bases
*Research compiled June 2026 — sources: engineering blogs, Chroma research, X/Twitter, practitioner write-ups*

---

## 1. The Core Framework: "Context Engineering"

The dominant term that emerged mid-2025 is **context engineering** — coined in practice by Shopify CEO Tobi Lütke (June 18, 2025) and formally endorsed by Andrej Karpathy on X (June 25, 2025):

> "Context engineering is the delicate art and science of filling the context window with just the right information for the next step." — @karpathy

The OS analogy now dominates practitioner thinking: **LLM = CPU, context window = RAM**. The agent framework/orchestrator acts as the OS — deciding what to page in and when. Cognition (makers of Devin) went further: "Context engineering is effectively the #1 job of engineers building AI agents."

LangChain's July 2025 framework post formalizes four operations:
- **Write** — save information outside the context window (scratchpads, long-term memories)
- **Select** — pull relevant context in just-in-time (RAG, file reads, memory retrieval)
- **Compress** — summarize or trim to retain only what's needed
- **Isolate** — split context across sub-agents or sandboxes

---

## 2. Context Rot: The Evidence Base

**Chroma Research (July 2025)** ran the most cited benchmark: 18 production LLMs (GPT-4.1, Claude 4, Gemini 2.5, Qwen3) on multi-hop reasoning tasks across 10,000–500,000 token contexts. Finding: *every single model showed monotonically decreasing F1 scores as input length grew*. Performance drops of 20–50% were observed between 10k and 100k+ tokens.

Mechanisms identified:
- **Lost-in-the-middle**: models attend well to start and end, poorly to the middle — 30%+ accuracy drop
- **Attention dilution**: quadratic transformer attention spreads thin over long contexts
- **Distractor interference**: semantically similar but irrelevant content actively misleads the model

Drew Breunig's June 2025 post ("How Long Contexts Fail") names four failure modes for agents specifically:
- **Context Poisoning**: a hallucination enters context and compounds (documented in Gemini's Pokémon-playing agent — once the "goals" section was poisoned, the agent looped indefinitely)
- **Context Distraction**: beyond ~100k tokens, Gemini's agent started *repeating past actions* from history rather than generating new plans — it over-indexed on accumulated context vs. its training
- **Context Confusion**: superfluous tools and docs get picked up anyway — Berkeley Function-Calling Leaderboard shows *every* model performs worse with more tools; a quantized Llama 3.1 8b failed with 46 tools but succeeded with 19
- **Context Clash**: contradictory information from multiple sources derails reasoning; Microsoft/Salesforce found sharded prompts caused a 39% average performance drop (o3 dropped from 98.1 to 64.1)

**Practical ceiling**: Databricks found model correctness began falling around 32k tokens for Llama 3.1 405b — well below the advertised context window. The implication: big context windows are useful for *retrieval and summarization*, not for multi-step generative reasoning.

---

## 3. Just-In-Time Retrieval vs. Pre-Loading

The practitioner consensus has moved decisively toward **just-in-time (JIT) retrieval** over pre-loading everything. Key principles:

**File system as context** (arxiv 2512.05470): the filesystem path itself is a retrieval signal — naming conventions, directory structure, and timestamps are cheap metadata that let agents locate relevant context without loading it. Progressive disclosure starts from the index, not the content.

**Progressive disclosure pattern** (HumanLayer, MindStudio, Ardalis 2025): structure information in layers so that platforms load name/description first, full content only when needed, supporting materials only during execution. Claude Code implements this natively — `CLAUDE.md` files in subdirectories load *on demand* when Claude reads files in those directories, not at session start.

**Practical implementation** (Opalic, Jan 2026): keep `CLAUDE.md`/`AGENTS.md` to a table of contents with file pointers, not the content itself. Include an `**IMPORTANT:** Read relevant docs before starting` instruction so the agent actually fetches them. Keep `CLAUDE.md` under 50–60 lines; docs live in `docs/` or `agent_docs/`.

**Agentic retrieval via grep/glob**: Claude Code's own architecture is a hybrid — `CLAUDE.md` upfront, then the agent uses `glob` and `grep` to navigate and retrieve files just-in-time. This is the model to emulate in a KB structure.

---

## 4. Agent Memory Patterns

LangChain's memory taxonomy (2025) draws from cognitive science:

| Memory Type | What It Stores | Mechanism |
|---|---|---|
| **Episodic** | Specific past interactions, decisions with timestamps | Session logs, dated notes |
| **Semantic** | Facts, preferences, codebase knowledge | Knowledge base docs, wiki |
| **Procedural** | How to do things — workflows, conventions | CLAUDE.md/AGENTS.md, runbooks |

**Key insight**: an agent that summarizes at write time collapses distinct episodes into semantic generalizations, destroying the episodic signal. Write-time vs. read-time compression is an active design choice.

**Status: stored vs. inferred** — practitioners distinguish between state that should be *explicitly persisted* (current sprint goal, blocked tasks, architectural decisions) vs. state that should be *inferred fresh each time* (current file contents, test status). Over-storing inferred state creates stale context; under-storing persistent state forces re-explanation.

**Scratchpad pattern**: Anthropic's multi-agent researcher uses a scratchpad as the agent's first action — writing its plan to a memory file because "if the context window exceeds 200,000 tokens it will be truncated and it is important to retain the plan." The scratchpad is a safety valve, not a primary store.

**Self-improving KB**: the `obsidian-mind` system (Ferrari/Menon, Apr 2026) and Opalic's `/learn` command both implement a *capture-then-classify* loop: the agent analyzes each session, extracts non-obvious learnings, and files them into the KB. The KB grows from actual use rather than upfront documentation.

---

## 5. Anti-Patterns

### 5.1 Stuffed Instruction Files
The most cited anti-pattern. ETH Zurich found context files can *reduce* agent success rates when poorly structured. HumanLayer's research (citing arxiv 2507.11538): frontier models reliably follow 150–200 instructions; Claude Code's own system prompt consumes ~50. A 1,000-line `CLAUDE.md` means only ~20–30% of your instructions are followed — and the degradation is *uniform*, not "bottom of file first."

Rule of thumb: if the config file exceeds 300–500 lines, most of it is noise. HumanLayer keeps theirs under 60 lines.

### 5.2 Prose About Lint Rules
Putting code style, formatting, and type rules in instruction files wastes instruction budget on things a linter enforces deterministically and faster. ESLint/Prettier/TypeScript configs *are* the rules; the agent reads violations from tool output.

### 5.3 Doc Sprawl / Proliferation
Multiple agents holding contradictory versions of the same fact = "silent behavioral drift" (Obsidian Security). The fix is one canonical layer, not parallel copies. Flat markdown without links = "a wiki, not a memory system" (OpenLobster critique). Notes without backlinks are a structural bug.

### 5.4 Stale Context
Agent memory that isn't versioned or timestamped becomes stale context silently. Architecture Decision Records (ADRs) without dates, project status notes that aren't updated, duplicate docs maintained in parallel — all poison the context window with outdated facts.

### 5.5 Over-connected MCP Tools
Too many tool definitions in the context cause confusion — Berkeley Function-Calling Leaderboard shows this degrades *every* model. Vercel's evals found AGENTS.md with a compressed docs index achieved 100% pass rate; skills invoked on-demand maxed at 79% and in 56% of cases weren't invoked at all. Static, well-structured docs outperformed dynamic tool invocations in their benchmark.

### 5.6 Preloading Everything
Loading full file contents at session start rather than excerpts/filenames. The obsidian-mind tiered strategy loads ~2K tokens always (excerpts + filenames), targeted tokens on semantic query, and full reads only when explicitly needed. The vault can scale to hundreds of notes without blowing the budget.

---

## 6. Implications for a Per-Directory `agents.md` KB

These findings translate directly to a cascading `agents.md` structure where each directory level carries its own instruction file.

### 6.1 The Hierarchy's Job

Each level should answer a different question:

| Level | Carries | Does NOT carry |
|---|---|---|
| **Root `AGENTS.md`** | Project WHY, top-level structure map, pointer index to subdirs, universal conventions | Any subproject-specific context |
| **Domain/area `agents.md`** | Area-specific workflows, key concepts, doc pointers for this domain | Cross-domain rules (already in root) |
| **Project/feature `agents.md`** | Current status, active decisions, gotchas, "read these files first" list | Historical context (move to archive) |
| **Leaf-level docs (`agent_docs/`)** | Deep gotchas, architecture diagrams, runbooks | Anything that belongs higher up |

### 6.2 Anti-Proliferation Rules

**One file per level — no exceptions.** If you find yourself creating `agents.md`, `context.md`, `notes.md`, and `instructions.md` in the same directory, you have doc sprawl. Consolidate into one file with sections, or move depth into `agent_docs/`.

**Content = pointer or decision, never both in full.** An `agents.md` file should either (a) point to where to find something, or (b) record a decision/status. It should not be the document itself. The document lives in `agent_docs/` and the `agents.md` carries a one-line pointer with a description: `docs/auth-gotchas.md — JWT edge cases and refresh token handling`.

**Size budget per level:**
- Root: 80–120 lines max (structure map + pointers)
- Domain: 40–60 lines
- Project: 30–50 lines (current status is the core value)
- Leaf docs: unlimited, but each file should be single-topic

### 6.3 Keep Instruction Files Lean

Apply the HumanLayer/Opalic rule: the `agents.md` file should contain only **universally applicable** context for that directory's scope. If an instruction only matters for one specific task, it belongs in a task-specific doc that gets loaded on demand.

Use the "linter test": can a tool enforce this rule deterministically? If yes, don't write prose about it — point to the linter config instead.

### 6.4 Naming as Retrieval Signal

Directory and file names are JIT retrieval signals before any content is read. Practitioners (arxiv 2512.05470, obsidian-mind) emphasize that the filesystem path itself conveys meaning. Implications:
- Directory names should reflect the cognitive domain, not org chart names
- Doc filenames should be self-describing: `auth-jwt-gotchas.md` not `notes.md`
- Use dates or status prefixes on ephemeral docs: `2026-06-sprint-goals.md`
- Avoid generic containers (`misc/`, `notes/`, `context/`) — they become retrieval black holes

### 6.5 Status: Stored vs. Inferred

At the project level, `agents.md` files should carry **stored state** (current sprint goal, known blockers, active architectural decisions, links to current tickets) because this is what an agent cannot infer from code alone.

Do NOT store state that can be inferred (current file contents, test results, PR status) — this creates stale context. Link to the source instead: "current PR status: see Jira board link" not a copy of ticket descriptions.

### 6.6 Episodic Memory Lives in Dated Docs, Not `agents.md`

Session logs, retrospectives, and decision records belong in dated files in `agent_docs/` or an archive — not in the live `agents.md`. The `agents.md` carries only *current* context. Historical context is fetched on demand when directly relevant.

This mirrors how the Obsidian-mind system structures its vault: `brain/` for current North Star / active state, `work/archive/` for history, `thinking/` as a scratchpad that gets promoted or deleted.

### 6.7 Cross-Directory Consistency

Root-level `AGENTS.md` should define the **meta-protocol**: how subdirectory `agents.md` files are structured, what each level is expected to carry, and which files are always-read vs. on-demand. This prevents drift where one subdirectory's `agents.md` accumulates 800 lines while another has 5.

Include an explicit maintenance contract: "When a project ships, the project-level `agents.md` moves to `Archive/` unchanged. Do not update it — let the archive be the history."

---

## 7. Summary Principles

1. **Context is RAM, not disk.** Load only what the current task needs. Structure the KB to make JIT loading easy, not pre-loading comprehensive.

2. **Smaller and scoped beats larger and general.** A 50-line `agents.md` that is 100% relevant outperforms a 500-line file that is 30% relevant. The degradation is uniform — noise harms everything, not just what it's near.

3. **Names and structure are retrieval signals.** Design directory names, filenames, and section headers as the first layer of retrieval before content is even read.

4. **Write pointers, not copies.** Instruction files should index documents, not contain them. Documents live in `agent_docs/` and are fetched on demand.

5. **Store decisions and status, not inferred state.** `agents.md` files at the project level carry what the agent cannot infer: current goals, active blockers, known gotchas, architectural choices. Not what it can read from files.

6. **One file per level, with a maintenance contract.** Prevent doc sprawl with a strict one-instruction-file-per-directory rule. Enforce it at the root level.

7. **Let the KB grow from use, not upfront.** Implement a capture loop (e.g., a `/learn` command or a session-end hook) so the KB accumulates real gotchas from real sessions rather than hypothetical documentation written cold.

---

## Sources

- [Context Rot: How Increasing Input Tokens Impacts LLM Performance — Chroma Research (Jul 2025)](https://www.trychroma.com/research/context-rot)
- [LLM Context Rot — Cobus Greyling, Medium](https://cobusgreyling.medium.com/llm-context-rot-28a6d0399655)
- [How Long Contexts Fail — Drew Breunig (Jun 22, 2025)](https://www.dbreunig.com/2025/06/22/how-contexts-fail-and-how-to-fix-them.html)
- [Context Engineering for Agents — LangChain Blog (Jul 2, 2025)](https://www.langchain.com/blog/context-engineering-for-agents)
- [Andrej Karpathy on X — "context engineering" (Jun 25, 2025)](https://x.com/karpathy/status/1937902205765607626)
- [Writing a good CLAUDE.md — HumanLayer / Kyle (Nov 25, 2025)](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Stop Bloating Your CLAUDE.md: Progressive Disclosure for AI Coding Tools — Alexander Opalic (Jan 18, 2026)](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/)
- [Your AI Coding Agent Forgets Everything. This Obsidian Vault Fixes That. — Menon Lab (Apr 14, 2026)](https://themenonlab.blog/blog/obsidian-mind-persistent-memory-ai-coding-agents/)
- [Progressive Disclosure in AI Agents: How to Load Context Without Killing Output Quality — MindStudio](https://www.mindstudio.ai/blog/progressive-disclosure-ai-agents-context-management)
- [CLAUDE.md, AGENTS.md & Copilot Instructions: Configure Every AI Coding Assistant — DeployHQ](https://www.deployhq.com/blog/ai-coding-config-files-guide)
- [Everything is Context: Agentic File System Abstraction for Context Engineering — arxiv 2512.05470](https://arxiv.org/pdf/2512.05470)
- [Anthropic: Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Types of AI Agent Memory: Episodic, Semantic, Procedural — Atlan](https://atlan.com/know/types-of-ai-agent-memory/)
- [How Does Memory for AI Agents Work? — Paul Iusztin, Decoding AI](https://www.decodingai.com/p/how-does-memory-for-ai-agents-work)
- [Mastering Personal Knowledge Management with Obsidian and AI — Eric Ma (Mar 2026)](https://ericmjl.github.io/blog/2026/3/6/mastering-personal-knowledge-management-with-obsidian-and-ai/)
