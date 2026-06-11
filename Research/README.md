# Research

Centralized home for all research source cards, organized by topic cluster. Every per-source thin reference lives here. No source cards anywhere else in the KB.

## Clusters
| Cluster | Topic | Status | Synthesis routed to |
|---|---|---|---|
| `01-agent-context-engineering` | Agent context/retrieval/KB best practices — Anthropic doctrine, AGENTS.md standard, practitioner discourse | research-complete | KB design (README.md Part 2–3) |
| `02-agent-tooling-conventions` | Per-tool agent files · Skills & Modules · KB ↔ shared repo interaction · Company-wide skill sharing | research-complete | Synthesis files in cluster dir |

## How to use
- Read a cluster's `README.md` + the synthesis — don't open every source file (attention budget).
- New deep dive → use the `deep-research` skill (fan-out); quick lookup → a single dated note.

## Adding a new cluster
1. Create `NN-<cluster-slug>/` (NN = next sequence number).
2. Add a `README.md` describing the cluster scope and status.
3. Use `PAPER-TEMPLATE.md` for each source card.
4. Route the synthesis to where it's used (`Docs/` for general, `Projects/<X>/` for project-specific).
5. Update this table.
