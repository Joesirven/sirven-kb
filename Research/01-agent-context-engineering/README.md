---
title: "Agent Context Engineering — research cluster"
type: readme
status: research-complete
updated: 2026-06-06
topic_cluster: agent-context-engineering
---

# Agent Context Engineering — cluster index

Research on how to structure a multi-tool agent knowledge base (context, retrieval, memory, per-directory `agents.md`). **Lightweight run** (3 parallel subagents synthesizing web sources) — *not* a full `deep-research` PAPER-TEMPLATE fan-out, so these are synthesis notes, not verbatim single-source files.

| File | Focus | as_of | revisit_when |
|---|---|---|---|
| `research-anthropic.md` | Anthropic doctrine: context engineering, attention budget, context rot, JIT retrieval, sub-agents → per-dir implications | 2026-06-06 | 2026-12-01 |
| `research-agentsmd.md` | AGENTS.md standard + nested/monorepo cascade, progressive disclosure, lean files, what each level carries | 2026-06-07 | 2026-12-01 |
| `research-practitioners.md` | Practitioner/X discourse: context rot (Chroma benchmark), JIT vs pre-load, memory patterns, anti-proliferation | 2026-06-06 | 2026-12-01 |

**Synthesis →** feeds `tmp/KB-design-proposal.md` (the per-level agents.md proposal). Once approved, the synthesis lands in `Ops/` and this cluster goes read-only.
