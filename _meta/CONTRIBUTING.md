# CONTRIBUTING.md

> How to safely edit this repo. Read `docs/DESIGN-RATIONALE.md` before changing any convention.

---

## Before you change a convention

Every structural convention in this repo has a reason. The reason lives in `docs/DESIGN-RATIONALE.md`. If you are about to change how `agents.md` files are sized, how modules work, how decisions are recorded, or how skills are packaged, read the relevant section there first. The rationale is not decoration — it prevents re-introduction of known failure modes (status-field drift, skill-source vs. installed gap, context bloat, etc.).

---

## Cascade and lean rules

### The cascade
- Root `AGENTS.md` cascades into every child `agents.md`. A child file inherits all root rules and adds only what is genuinely local to its directory.
- `README.md` = human narrative (what this area is for, how to navigate it).
- `agents.md` = agent rules and process (what the agent should do here, what it can edit, where to write outputs).
- These are different audiences. Do not merge them.

### Size limits
| File | Soft limit | What to do if you exceed it |
|---|---|---|
| Root `AGENTS.md` | ~45 lines | Use Datadog router pattern: add a line pointing to a per-area `agents.md` rather than growing the root |
| Child `agents.md` | ~80 lines | Extract content into a module or reference doc; point to it from the `agents.md` |
| A module in `Ops/System/modules/` | ~40 lines | Split into a base module + inheriting child, or promote content to a skill with `references/` files |
| Any skills file | ~5k tokens | Move deep content to a `references/` subdirectory file; reference it from the SKILL.md body |

CI lint enforces these limits on merge. A PR that pushes any `AGENTS.md` past 200 lines will fail.

---

## Adding or changing a module

Modules in `Ops/System/modules/` are the single source of truth for capability logic. Changes here propagate everywhere the module is used — by skills, scheduled tasks, and any agent that loads the module directly.

**To add a new module:**
1. Create `Ops/System/modules/<capability-name>.md`.
2. Document the module interface at the top of the file (scope, trigger, inputs, outputs).
3. If the module extends another module, add `> inherits: Ops/System/modules/<base>.md` as the first non-blank line.
4. Register the module in `Ops/System/agents.md` under the `modules/` rules section.
5. Record the decision in the nearest `decisions.md` (see below).

**To change an existing module:**
1. Read `docs/DESIGN-RATIONALE.md` §2 (modules) before editing.
2. Edit the single module file. The change propagates automatically to everything that calls it — you do not need to find and update callers.
3. If the change alters the module's interface (inputs, outputs, or trigger conditions), check whether any skill's `SKILL.md` that calls this module needs an update to its delegation language.
4. Bump the repo version in `.claude-plugin/marketplace.json` (patch for backward-compatible changes, minor for interface changes).
5. Append a decision entry if the change reflects a new policy or convention (see below).

---

## Adding or changing a skill

Skills live under `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`. They are thin wrappers that invoke modules with parameters.

**To add a new skill:**
1. Create `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`.
2. Keep the SKILL.md body under ~40 lines. Deep content goes in `references/` files inside the skill directory.
3. Register the skill in `.claude-plugin/marketplace.json` under the appropriate plugin's `skills` array.
4. Bump the version in `marketplace.json` (patch for additions).
5. Commit, tag, push. Teammates run `/plugin marketplace update sirven-kb` to pull.

**To change an existing skill:**
1. Edit the SKILL.md (or the relevant `references/` file if the skill uses one).
2. Bump the version in `marketplace.json` — without a version bump, Claude Code serves the cached copy.
3. Tag and push.

**The forced-eval hook:** The first skill in the `kb-workflows` plugin must remain a forced-eval hook. Do not remove it or reorder it to a later position. Without it, skill activation drops from ~84% to ~20%. See `docs/DESIGN-RATIONALE.md` §6.

---

## Recording a decision

Any change to a convention, module interface, or skill architecture should be recorded as a keyed entry in the nearest `decisions.md`.

**Format** (from `Ops/System/modules/decision-log.md`):
```
### <ISO date> — <decision-key>
- **Decision:** <what was decided>
- **Why:** <terse rationale>
- **Implemented in:** <file/section where it takes effect>
- **Supersedes:** <prior entry date for same key, or —>
```

**Currency rule:** The current decision for a key = the newest entry for that key. Never add `status: superseded` or `status: active` fields. Never edit existing entries. Append only.

**Granularity:** Each entry should be independently supersedable. If you are changing two unrelated things, write two entries with different keys.

---

## The PR-back flow

This repo is the upstream parent for personal and team forks. Improvements discovered in any fork belong here if they are generic and shareable.

1. Fix the issue in your fork.
2. Open a PR to this repo targeting `main`.
3. `CODEOWNERS` (or ) gates PRs touching `AGENTS.md`, `CLAUDE.md`, or `Ops/System/modules/`. At least one DX/platform owner must approve.
4. Squash-merge. After merge, tag a new semver release.
5. Forks pull: `git fetch upstream && git merge upstream/main`.
6. CI runners pinned to a tag are updated by bumping the tag in the provisioning script.

**What belongs in a PR here vs. stays in your fork:**
- Generic convention or module improvement → PR here.
- Personal project knowledge, org-specific workflows, personal preferences → stays in personal fork or `~/.claude/CLAUDE.md`.
- If in doubt: "Would this be equally correct and useful for a teammate at a different company?" If yes, it belongs here.

---

## What NOT to add to this repo

The following content must never appear in any committed file in this repo:

- Personal paths (e.g., `~/path/to/your-private-vault/...`)
- Personal project references or personal goals
- Credentials, tokens, API keys, or `.env` content
- Org-specific hostnames, internal URLs, or internal project names
- Content that is only meaningful on one person's machine

These belong in `~/.claude/CLAUDE.md` (personal global layer), `./CLAUDE.local.md` (gitignored per-repo personal), or the personal fork. See `docs/DESIGN-RATIONALE.md` §5 and §7 for the full rationale.

---

## Versioning quick reference

- **Patch** (`v1.0.x`): clarification, typo fix, backward-compatible module addition.
- **Minor** (`v1.x.0`): new module, new skill, new area template, new capability.
- **Major** (`vX.0.0`): breaking change to cascade conventions or module interfaces.

Append one entry to `CHANGELOG.md` per tag. It is append-only.
