# module: subagent-orchestration

> Applies to: game-master agents and any agent spawning sub-tasks.

## Core principles
- **Divide non-trivial work** into focused subagents; the master stays active (planning, reviewing) — never idle while subagents run.
- **Disjoint ownership:** each subagent owns a disjoint file set / subtree; no two subagents write the same file (avoids conflicts).
- **Maker → checker:** every builder output is reviewed by a separate checker agent before acceptance; the master mediates.
- **Outputs by reference:** subagents write to `tmp/` and return paths; they do not paste large content into the orchestration thread.
- **Plan first:** write the plan to `tmp/` before fan-out; record resulting decisions in the nearest `decisions.md`.
- **Parallelize / serialize correctly:** independent calls go in one message (true parallelism); serialize only when there is a true data dependency.

## Inheritance
A module may add `> inherits: <module-path>` at the top and layer rules on top without repeating the base. Consumers of the inheriting module implicitly follow the base module's rules.
