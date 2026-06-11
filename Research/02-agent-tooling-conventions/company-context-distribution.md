---
title: "Company-Wide Shared Agent Context Distribution — CLAUDE.md / AGENTS.md"
type: research
status: research-complete
updated: 2026-06-08
as_of: 2026-06-08
revisit_when: "2026-12-01 or when Anthropic ships native team-sync / Project Knowledge API for Claude Code"
topic_cluster: agent-tooling-conventions
source_type: synthesis
source_url: "https://code.claude.com/docs/en/memory"
related:
  - "kb-repo-interaction.md"
  - "per-tool-agent-files.md"
  - "skills-and-modules.md"
tags:
  - CLAUDE.md
  - AGENTS.md
  - team
  - enterprise
  - distribution
  - git-submodule
  - npm
  - MCP
  - managed-settings
  - PR-back
  - Bitbucket
  - Ramp
  - Datadog
  - Boris-Cherny
  - CODEOWNERS
---

# Company-Wide Shared Agent Context Distribution

**TL;DR** — No org has a perfect solution yet; the ecosystem is converging on three viable patterns. The simplest that actually scales is a **central git repo** (one source of truth) that each laptop/server clones or references, combined with a **PR-back model** identical to code review. The Anthropic-official "managed policy" layer (`/etc/` / `/Library/Application Support/ClaudeCode/CLAUDE.md`) is the correct distribution target for org-wide behavioral rules and is deployed via MDM/Ansible. Project-level shared context lives in a committed repo CLAUDE.md. The personal layer (`~/.claude/`) stays machine-local. Boris Cherny's documented Anthropic practice — one team CLAUDE.md in git, updated multiple times per week, never left to drift — is the closest thing to a validated playbook.

---

## TL;DR (signal-first — read this; the rest is JIT)

1. **Four official CLAUDE.md scopes exist** (as of docs fetched 2026-06-08): Managed policy (`/etc/claude-code/CLAUDE.md` on Linux, `/Library/Application Support/ClaudeCode/CLAUDE.md` on macOS) → User (`~/.claude/CLAUDE.md`) → Project (`./CLAUDE.md` / `./.claude/CLAUDE.md`) → Local (`./CLAUDE.local.md`). Managed cannot be excluded by individual settings. This is the official org-wide hook.
2. **Anthropic's own practice** (Boris Cherny, Jan 2026, verified from two sources): one CLAUDE.md committed to each project's git repo, shared by the whole team, updated multiple times per week using the rule "when Claude does something wrong, add it." This is the simplest pattern that demonstrably works at scale (Anthropic-team level).
3. **Three distribution mechanisms scale differently**: (a) **Central git repo + clone/submodule/symlink** — works for any team, degrades on submodule neglect; (b) **npm/pip package** — explicit versioning, Renovate/Dependabot automation, cleanest for multi-repo shops; (c) **MDM-deployed managed CLAUDE.md** — enforced org-wide on every machine, immune to individual override, ideal for security/compliance rules.
4. **MCP-served context** is an emerging fourth path (Letta Context Repositories, Feb 2026) — git-backed memory shared across subagents via worktrees and merge. Not yet mainstream for org-wide CLAUDE.md distribution specifically, but shows where this is heading.
5. **PR-back model** should mirror code review: CODEOWNERS on `.claude/` and `CLAUDE.md`, two-reviewer gate, squash-merge, semantic versioning tags for the shared context repo. Without an owner/reviewer, shared CLAUDE.md drifts to bloat within months (case study: 30-dev shop, CLAUDE.md past 800 lines → teams stalled at basic installation, 2026).
6. **Monolithic vs. per-team files**: Datadog's Simon Boudrias (Sep 2025) recommends a root AGENTS.md as a *router* pointing to per-folder/per-team AGENTS.md files — progressive disclosure at scale. This is the proven monorepo pattern. Anthropic's official docs add `.claude/rules/*.md` for path-scoped rules that only load when Claude touches matching files. Both agree: a single 1000+ line file is an anti-pattern.
7. **Bloat is the primary failure mode**. Under 200 lines per file: Claude reads reliably. 200–500: workable with structure. Past ~800: unpredictable adherence. The only fix is CODEOWNERS + mandatory quarterly pruning (mark a fixed owner; add a recurring calendar event; block PRs that push past the line limit via CI lint).

---

## 1. Distribution to Devices and Servers — Pattern Inventory

### 1a. Managed Policy Layer (Anthropic-official, org-enforced)

**Locations:**
- macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`
- Linux/WSL: `/etc/claude-code/CLAUDE.md`
- Windows: `C:\Program Files\ClaudeCode\CLAUDE.md`

**Deployment:** MDM (Jamf, Kandji, Intune), Ansible, Group Policy, Chef/Puppet. Alternatively, embed content directly in `managed-settings.json` under the `claudeMd` key.

**Properties:** Loads before every other CLAUDE.md scope. Cannot be excluded by `claudeMdExcludes` or any user/project setting. Applies to every repository on the machine. This is the correct layer for security policies, compliance reminders, org-wide behavior rules that must not drift.

**Scale verdict:** Scales perfectly — you already have an MDM fleet. Rots when: you forget to update the MDM payload (the file on disk diverges from the latest source-of-truth repo). Fix: automate MDM payload from a CI pipeline that fires on every merge to the shared context repo's `main`.

**Source:** Anthropic official docs, fetched 2026-06-08 (https://code.claude.com/docs/en/memory)

### 1b. Central Git Repo + Clone / Submodule / Symlink

**Pattern:** Create a dedicated repo (e.g., `agent-kb-base`) containing:
```
agent-kb-base/
  CLAUDE.md              # org-wide base rules
  AGENTS.md              # cross-tool shared standard
  .claude/rules/
    security.md          # path-scoped: applies to all repos
    style.md
  skills/                # shared slash commands
```

Each project repo adds this as a **git submodule** and symlinks `.claude/rules/shared` → the submodule's rules directory. A per-project CLAUDE.md imports:
```markdown
@agent-kb-base/CLAUDE.md

## Project-specific additions
...
```

**Propagation:** `git submodule update --remote && npm run install-commands` — scripted. CI runs this on a schedule; Dependabot/Renovate opens PRs for submodule hash bumps.

**Scale verdict:** Works for teams with git discipline. Degrades when developers ignore `git submodule update` and the pinned hash goes stale. The MindStudio analysis (May 2026) calls submodule drift the primary failure mode and recommends Renovate automation to prevent it.

**Source:** MindStudio, "How to Build a Modular Skill System in Claude Code for Multiple Clients," May 27, 2026 (https://www.mindstudio.ai/blog/modular-skill-system-claude-code-multiple-clients)

### 1c. npm / pip Package Distribution

**Pattern:** Package the shared CLAUDE.md and rules as `@yourorg/agent-context` (npm) or `yourorg-agent-context` (pip). Include a `postinstall` script that copies/symlinks files into `.claude/rules/`. Clients add it to `devDependencies`. Renovate opens auto-PRs on every new release.

```json
{
  "name": "@yourorg/agent-context",
  "version": "1.4.0",
  "scripts": {
    "postinstall": "node scripts/install-agent-context.js"
  }
}
```

**Propagation:** CI publishes on every merge to main. Semantic versioning: breaking changes = major bump. Renovate/Dependabot covers the propagation automatically.

**Scale verdict:** Cleanest for multi-repo shops. Explicit versioning means rollback is one version bump. Operational overhead: you need an internal npm/pip registry (or use a private GitHub Packages / Artifactory registry). Rots when: the registry isn't maintained or auth tokens expire.

**Source:** MindStudio (May 2026), supported by GitHub claude-code-ultimate-guide analysis

### 1d. `@import` from Shared File / `~/.claude/CLAUDE.md`

**Pattern:** Put org-wide rules in `~/.claude/CLAUDE.md` (user scope) or in `~/.claude/rules/*.md`. Each developer's dotfiles repo (chezmoi, yadm, homeshick) distributes this file. Individual projects import team-standard files via `@` syntax in their own CLAUDE.md.

**Scale verdict:** Works for user-scope rules that aren't org-mandated. Rots fast in orgs without a dotfiles culture — developers who don't use dotfiles managers get nothing. Not suitable as the *only* distribution mechanism; works well as a *complement* to the managed layer (user-scope = personal overrides; managed = org mandates).

### 1e. MCP-Served Context (Emerging)

**Pattern:** Run a centralized MCP server that exposes the org's agent context as tools/resources. Each developer's Claude Code session connects to the server. Updates deploy once, take effect everywhere immediately — no per-machine file management.

**Scale verdict:** Most operationally powerful but most complex. Requires authentication, zero-downtime deploys, handling schema changes without breaking running sessions. Letta's Context Repositories (Feb 2026) demonstrates git-backed memory shared across subagents via worktrees — the architectural predecessor to org-wide MCP-served context. Not mainstream for CLAUDE.md distribution yet, but the right direction for organizations that already run internal MCP infrastructure.

**Source:** Letta, "Introducing Context Repositories: Git-based Memory for Coding Agents," Feb 12, 2026 (https://www.letta.com/blog/context-repositories)

---

## 2. PR-Back / Contribution Model

### What works at Anthropic (Boris Cherny, Jan 2026)

> "His team keeps one shared CLAUDE.md checked into git. Everyone updates it multiple times a week. The rule: when Claude does something wrong, add it so it doesn't repeat. Boris often uses the `@.claude` tag on coworkers' PRs to add learnings to CLAUDE.md."

Source: "How Boris Cherny Uses Claude Code," howborisusesclaudecode.com, Jan 2026; confirmed in Boris's X post (x.com/bcherny/status/2007179832300581177) and team tips gist (gist.github.com/joyrexus/e20ead11b3df4de46ab32b4a7269abe0, last updated Apr 2026).

Key mechanics from the Anthropic model:
- **Contribution trigger:** Claude error → fix → immediately ask Claude to update CLAUDE.md ("Compounding Engineering")
- **PR in the flow:** `@.claude` tag on PRs triggers GitHub Action that proposes CLAUDE.md edits
- **Cadence:** Multiple times/week — not a scheduled quarterly review
- **Gate:** PR review (implicit — same as any code change)

### Formal governance layer (adds CODEOWNERS)

For a **shared context repo** with company-wide PRs:

1. `CODEOWNERS` assigns `.claude/` and `CLAUDE.md` to a named DX/platform team member (1–2 people max). Every PR touching these files requires their approval.
2. Two-reviewer rule for breaking changes (major version bumps).
3. CI lint step: fail if any CLAUDE.md exceeds 200 lines; fail if a rules file has no `paths:` frontmatter (enforce scope).
4. Semantic versioning tags (`v1.2.0`) on the shared context repo — consumers (submodule pins, npm package) reference a tag, not `main`.
5. **Quarterly pruning sprint:** CODEOWNERS owner reviews the full file; removes entries older than 6 months that haven't been cited in a PR in 90 days; bumps minor version.

### Anti-patterns that cause drift and bloat

- **No owner:** "When everyone owns it, nobody does." Skills go stale, CLAUDE.md drifts past 800 lines, adherence collapses. (30-dev shop case study, digitalapplied.com, 2026)
- **Auto-generated CLAUDE.md:** ETH Zurich AGENTbench (arXiv 2602.11988, Feb 2026): LLM-generated context files *reduced* task success by ~3% vs. no file. Only hand-written files gave +4%. `/init` is a starting point, not a maintenance strategy.
- **One monolithic file for 50+ engineers:** Datadog's Simon Boudrias (Sep 2025) explicitly calls this out — use a root router document that delegates to per-team / per-folder files. Progressive disclosure prevents any one section from bloating the shared base.
- **No version pinning:** Consumers on floating `main` break when a rule change is incompatible with their project's conventions. Always pin to a tag or submodule hash.

---

## 3. Real Org Practices: What Has Been Said

### Anthropic / Boris Cherny

> "Each team at Anthropic maintains a CLAUDE.md in git to document mistakes, so Claude can improve over time, and best practices, such as style conventions, design guidelines, PR template, and so on. His team keeps one shared CLAUDE.md checked into git. Everyone updates it multiple times a week."

Source: karozieminski.substack.com, "How Boris Cherny Uses Claude Code," Jan 2026; corroborated by InfoQ, "Inside the Development Workflow of Claude Code's Creator," Jan 2026.

Disagreement noted: Boris's setup is described as "surprisingly vanilla" — no heavy customization, CLAUDE.md is simple and project-scoped. Some practitioners advocate elaborate global layers; Boris uses minimal global config.

### Datadog (Simon Boudrias, Sep 2025)

> "A well-maintained AGENTS.md is the contract between your codebase and the agent ecosystem... At some point, centralized dev experience teams can't be experts in everything. Platform and product teams must own their own steering content. The central team provides the scaffolding (AGENTS.md, routing, shared configs). Each partner team fills in domain-specific instructions."

Source: dev.to/datadog-frontend-dev, "Steering AI Agents in Monorepos with AGENTS.md," Sep 26, 2025.

Key pattern: root AGENTS.md as **router**, not monolith:
```
# Tasks
To create an email, read @emails/AGENTS.md
To create a Go service, read @go/services/AGENTS.md
```

Also recommends `AGENTS.local.md` (gitignored) for per-user overrides, and `~/AGENTS.md` for global personal prefs.

Disagreement with Anthropic pattern: Datadog uses AGENTS.md (cross-tool standard) as the source of truth with CLAUDE.md importing it. Boris Cherny's team uses CLAUDE.md directly (Claude Code-only). For a multi-tool org, Datadog's approach is more portable.

### Ramp (Geoff Charles, CPO)

Ramp generated >1M lines of AI-suggested code in 30 days, with ~50% of engineers using Claude Code weekly. CLAUDE.md skills committed to the repo are part of their workflow — including a "PM skill" that Geoff shared publicly. No direct statement from Ramp on org-wide CLAUDE.md distribution mechanics; their emphasis is on **project-scoped skills** committed to individual repos rather than a shared base layer.

Source: creatoreconomy.so, "Inside Ramp, the $32B Company Where AI Agents Run Everything," 2025.

### Replit

No direct public statement on org-wide CLAUDE.md/AGENTS.md distribution from Replit's engineering team. Replit's docs focus on individual project use of Claude Code in their environment. The Claude Code vs. Replit comparison (Opsio, 2026) notes: Claude Code is "terminal-first, governed enterprise engineering"; Replit is "browser-first, rapid prototyping." Shared context distribution is more relevant to the Claude Code use case.

### Feature request status (GitHub issue #8395, Sep 29, 2025)

A filed feature request for user-level agent rules and propagation to subagents documents the gap: no mechanism exists to define user-level rules that propagate to subagents automatically. As of close, labeled `area:core` + `enhancement` but closed as `not planned`. The official answer is: use `~/.claude/CLAUDE.md` for user-scope rules; subagents inherit the project CLAUDE.md from the session context, not a separate propagation path.

A related open feature request (issue #39051) asks for syncing Claude.ai Teams Project Knowledge with Claude Code — real-time propagation without git push. Not yet shipped as of 2026-06-08.

---

## 4. Monolithic vs. Per-Team Files: The Disagreement

| Position | Advocates | Rationale |
|---|---|---|
| **Monolithic project CLAUDE.md** | Boris Cherny / Anthropic | Simple, always loaded, no navigation overhead. Works for a single team on a single project. |
| **Router root + per-folder files** | Datadog (Boudrias, Sep 2025) | Progressive disclosure; platform team owns root; product teams own their AGENTS.md leaf nodes. Right for monorepos with 5+ teams. |
| **npm/pip package with postinstall** | MindStudio (May 2026), practitioners | Explicit versioning + automated propagation. Right for multi-repo shops. |
| **Managed policy file via MDM** | Anthropic official docs (2026-06-08) | Org-wide enforcement that cannot be overridden. Right for security/compliance rules. |

**Synthesis:** These are not competing patterns for the same layer — they are complementary layers:
- **Managed** → non-negotiable org security/compliance rules
- **Shared repo (per-project CLAUDE.md)** → team conventions for a specific codebase
- **Router + leaf** → scale pattern for monorepos with multiple teams
- **npm package** → propagation mechanism for the shared repo content in a multi-repo org
- **`~/.claude/CLAUDE.md`** → personal style, never org-mandated

---

## 5. Concrete Recommendation for Jose: agent-kb-base on Bitbucket

### Setup

**Repo: `agent-kb-base` (Bitbucket, company-shared)**

```
agent-kb-base/
  AGENTS.md              # cross-tool source of truth
  CLAUDE.md              # "@AGENTS.md" + Claude-specific additions
  .claude/rules/
    security.md          # path-scoped org rules
    conventions.md       # org coding conventions
  skills/                # shared company slash commands
  CHANGELOG.md           # semantic versioning log
  .github/CODEOWNERS     # or Bitbucket equivalent
```

**Bitbucket CODEOWNERS equivalent:** Use Bitbucket's "Default reviewers" feature. Set jose (or a platform alias) as required reviewer for any PR touching `CLAUDE.md`, `AGENTS.md`, `.claude/`. This is the PR-back gate.

**Distribution to laptops:**

Option A (simplest): Each dev clones `agent-kb-base` once. A setup script symlinks:
```bash
ln -s ~/agent-kb-base/.claude/rules/shared .claude/rules/shared
```
Then project CLAUDE.md:
```markdown
@~/agent-kb-base/CLAUDE.md

## Project-specific additions
```

Caveat: `@` imports with `~/` paths work but trigger an approval dialog on first use per-project (Claude Code security prompt). Users must approve once.

Option B (managed layer for org-wide enforcement): Run an Ansible play / Jamf policy that copies the latest `agent-kb-base/CLAUDE.md` to `/etc/claude-code/CLAUDE.md` on every machine at startup. The CI pipeline in `agent-kb-base` triggers the MDM payload refresh on every merge to main. This is the correct path for rules that *must* be followed by everyone.

**Distribution to shared servers (CI/CD, agent runners):**

The agent runner's Dockerfile or provisioning script clones `agent-kb-base` and copies the managed CLAUDE.md to `/etc/claude-code/CLAUDE.md`. Pin to a version tag, not `main`, so a bad commit doesn't break all CI:
```bash
git clone --branch v1.4.0 https://bitbucket.org/yourorg/agent-kb-base.git /opt/agent-kb-base
cp /opt/agent-kb-base/CLAUDE.md /etc/claude-code/CLAUDE.md
```

### Personal KB (GitHub) — the child layer

Jose's personal KB on GitHub (`catalist-kb-personal` or equivalent) inherits from `agent-kb-base` via:

1. `~/.claude/CLAUDE.md` imports both the org base AND the personal vault context:
   ```markdown
   @~/agent-kb-base/CLAUDE.md
   @~/Documents/SirvenOS/Catalist/agents.md
   
   ## Personal preferences
   - Always use pnpm, not npm
   - Personal sandbox URL: ...
   ```
2. No committed pointer from the shared Bitbucket repo to the personal KB — the import lives in `~/.claude/CLAUDE.md` (machine-local, never committed).
3. Personal improvements flow *from* personal KB → PR to `agent-kb-base` when they're worth sharing with the org. The PR triggers the Default Reviewers gate.
4. Org changes flow *from* `agent-kb-base` → personal machine by pulling the repo (`git pull`). No auto-push to personal GitHub — they are genuinely independent trees.

### PR-back contribution loop

```
José notices Claude mistake in any project
  → fixes it
  → asks Claude: "Update CLAUDE.md with this rule"
  → Claude proposes a change to agent-kb-base/CLAUDE.md
  → José reviews, creates a PR to agent-kb-base
  → Default reviewer approves (or José self-approves if sole DX owner)
  → Merge triggers CI: publishes new version tag
  → All project CIs running Renovate/Dependabot pick up the new tag
  → MDM payload updates managed CLAUDE.md on all machines at next sync
```

For the personal GitHub KB: changes that are personal-only stay in `~/.claude/CLAUDE.md`. Changes that would help the whole org go into a PR on `agent-kb-base`.

### Anti-bloat controls

- CI lint in `agent-kb-base`: fail if any CLAUDE.md > 200 lines.
- Quarterly calendar reminder: prune entries that haven't been referenced in 90 days.
- For monorepo use: use the Datadog router pattern (root CLAUDE.md imports per-team files) rather than growing the root file.

---

## Key Data & Quotes (verbatim)

> "Every project needs a CLAUDE.md file checked into git. His team keeps one shared CLAUDE.md checked into git. Everyone updates it multiple times a week. The rule: when Claude does something wrong, add it so it doesn't repeat."
— Boris Cherny (Anthropic), howborisusesclaudecode.com / karozieminski.substack.com, Jan 2026

> "A well-maintained AGENTS.md is the contract between your codebase and the agent ecosystem... At some point, centralized dev experience teams can't be experts in everything. Platform and product teams must own their own steering content."
— Simon Boudrias (Datadog), dev.to/datadog-frontend-dev, Sep 26, 2025

> "When everyone owns the shared library, nobody does. Skills go stale. MCP servers break. CLAUDE.md drifts out of date."
— digitalapplied.com, "Claude Code Anti-Patterns: Team Adoption Failure Modes," 2026

> "Squads that pruned their CLAUDE.md to under 400 lines... shipped hooks and subagents in subsequent sprints, while squads that allowed files to drift past 800 lines stalled at basic installation."
— digitalapplied.com, "Case Study: Claude Code Adoption at a 30-Dev Shop 2026"

> "A modular system is only as good as its propagation mechanism. Three viable propagation strategies: git submodules with symlinks, npm package distribution, or a centralized MCP server."
— MindStudio, "How to Build a Modular Skill System in Claude Code for Multiple Clients," May 27, 2026

> "Organizations can deploy a centrally managed CLAUDE.md that applies to all users on a machine. This file cannot be excluded by individual settings."
— Anthropic, Claude Code official docs (code.claude.com/docs/en/memory), fetched 2026-06-08

---

## Source Quality / Limitations

- **Anthropic official docs** (code.claude.com/docs/en/memory): primary source, fetched live 2026-06-08. Authoritative for supported features and file locations.
- **Boris Cherny / howborisusesclaudecode.com, X post Jan 2026**: first-party account from Claude Code's creator. High signal; represents Anthropic's internal practice, not necessarily the best practice for every org.
- **Datadog / Simon Boudrias, Sep 2025**: practitioner first-party source, a leading engineering org, specific to monorepo + AGENTS.md (multi-tool) setup. Pre-dates some Claude Code features.
- **MindStudio, May 2026**: practitioner synthesis, commercially motivated (promotes their product), but the three-strategy framework and propagation mechanics are tool-agnostic and independently verifiable.
- **digitalapplied.com case study 2026**: practitioner field report; methodology and sample size not disclosed. Use as directional signal, not benchmark data.
- **GitHub issue #8395 (Sep 2025)**: first-party user feedback; confirmed gap in user-level rule propagation. Resolution: closed as not planned.
- **Letta Context Repositories, Feb 2026**: git-backed memory architecture; relevant as future direction, not current CLAUDE.md distribution practice.
- Ramp practices around org-wide CLAUDE.md distribution are inferred from Geoff Charles's public statements; no engineering blog post with explicit mechanics found.
