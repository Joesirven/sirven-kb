# agents.md — Projects (inherits /AGENTS.md)

**Scope:** per-project KB directories.

## Rules
- Each project lives in `Projects/<project-name>/` with its own `agents.md`, `00-README.md`, and `decisions.md`.
- Project `agents.md` inherits root rules and adds project-specific conventions (code repo locations, approved append targets, output paths).
- Limit: ≤ ~5 active projects at root level; archive completed projects to `Archive/`.
- Cross-project decisions → `Ops/System/decisions.md`. Project-scoped → `Projects/<X>/decisions.md`.
