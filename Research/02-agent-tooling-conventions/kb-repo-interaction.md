---
title: "Personal KB (Obsidian Vault) ↔ Shared Code Repo Agent Files — Interaction Model"
type: research
status: research-complete
updated: 2026-06-08
topic_cluster: agent-tooling-conventions
source_type: synthesis
related:
  - "per-tool-agent-files.md"
  - "skills-and-modules.md"
tags:
  - AGENTS.md
  - CLAUDE.md
  - Cursor
  - personal-KB
  - Obsidian
  - global-rules
  - CLAUDE.local.md
  - team-vs-personal
  - Bitbucket
  - git-exclude
  - symlinks
  - MCP
---

# Personal KB (Obsidian Vault) ↔ Shared Code Repo Agent Files

**TL;DR** — A private Obsidian vault and a shared Bitbucket repo are different trees that should never directly reference each other in committed files. Team conventions belong in a committed `AGENTS.md`; personal coding style and KB context belong in global personal layers (`~/.claude/CLAUDE.md`, Cursor User Rules) that never touch the repo. The KB reaches the coding agent via an MCP server or a gitignored local file, not via any committed pointer. The `AGENTS.md`-as-parent / tool-specific-overlay pattern applies fully within a single repo tree; when two separate trees (vault vs. repo) are involved, they stay independent and communicate only through the agent's global config or an MCP sidecar.

---

## TL;DR (signal-first — read this, rest is JIT)

1. **AGENTS.md in the shared repo = team-only, zero personal content.** Build commands, test commands, coding conventions, architecture decisions, PR norms. Nothing about your personal vault, your personal style, your sandbox URLs, or tool preferences. All of this is team-visible and committed.
2. **Personal layer sits entirely outside the repo.** Two official personal hooks exist: `~/.claude/CLAUDE.md` (applies to every Claude Code session on your machine regardless of repo) and Cursor **User Rules** (Cursor Settings > Rules, not in `.cursor/rules/`, not committed). Both are machine-local and invisible to teammates.
3. **`CLAUDE.local.md` is the per-repo personal escape hatch.** Gitignored by default. Put your sandbox URLs, local test tokens, personal workflow shortcuts for this repo only. Use `.git/info/exclude` (not `.gitignore`) to keep the exclusion invisible to teammates.
4. **The vault never appears in a committed repo file.** No symlink to `~/Documents/SirvenOS/Catalist/` committed to Bitbucket. No `@~/Documents/SirvenOS/...` import in a committed CLAUDE.md. If the vault must inform the coding agent, wire it via: (a) an Obsidian MCP server configured in Claude Code's local MCP config (not committed), or (b) an `@import` in `CLAUDE.local.md` pointing into the vault (gitignored).
5. **AGENTS.md is the shared parent; CLAUDE.md and `.cursor/rules/` are tool overlays.** Within a single repo, AGENTS.md holds cross-tool shared content; CLAUDE.md imports it and adds Claude-specific additions; `.cursor/rules/*.mdc` adds Cursor-specific glob-scoped rules. When the second tree is a separate vault (not a subdirectory of the repo), this parent/overlay pattern does not extend across trees — the vault is not a parent AGENTS.md.
6. **Obsidian-to-agent bridge = MCP server, local config only.** Projects like `obsidian-mcp-server` (cyanheads), `mcpvault`, and Nooscope expose the vault via MCP. Configure these in `~/.claude/` MCP config or Cursor's local settings — never in `.cursor/rules/` or `.mcp.json` committed to the repo.
7. **Private agent tooling for shared repos = symlinks + `.git/info/exclude`.** Per Irina Scurtu (Apr 2026): maintain a private `claude-configs/` repo, symlink `.claude/agents/` and `.claude/skills/` from each project into it, and exclude the symlinks via `.git/info/exclude` (never `.gitignore`). The repo stays clean; personal agents are versioned privately.

---

## 1. The Split in Detail: What Goes Where

### 1a. Committed to the Shared Bitbucket Repo

**`AGENTS.md` (team-shared, open standard)**
- Project purpose (one sentence — "role-based prompt" anchor for all agents)
- Package manager and non-standard tool choices
- Build, test, lint, type-check commands (exact, copy-paste-runnable)
- High-level directory layout (stable concepts, not file paths that drift)
- Critical coding conventions teammates would fail code review for violating
- PR/commit norms the whole team has agreed on
- References to stable internal docs (e.g., `@docs/API_CONVENTIONS.md`)

**What AGENTS.md must NOT contain:**
- Any personal preferences, personal tool shortcuts, personal sandbox URLs
- Pointers to `~/Documents/SirvenOS/Catalist/` or any personal vault path
- Personal Claude Code agent files or personal skills (these belong in the private config repo)
- Auto-generated boilerplate (ETH Zurich AGENTbench 2026: auto-generated context files reduce task success vs. hand-written)

**`CLAUDE.md` (team-shared, Claude Code overlay)**
- First line: `@AGENTS.md` (imports shared content, Windows-safe, no symlink needed)
- Below the import: Claude-specific additions teammates also need (plan mode rules, Claude-specific MCP notes for team MCP servers, etc.)
- Under 200 lines total (Claude Code official docs: over 200 lines degrades adherence)

**`.cursor/rules/*.mdc` (team-shared, Cursor overlay)**
- Glob-scoped rules for specific file types (e.g., `src/api/**/*.ts` → API conventions)
- Rules with `alwaysApply: true` for cross-cutting conventions
- Team Cursor norms that have no AGENTS.md equivalent (frontmatter-triggered activation)
- No personal style — these are committed and seen by all Cursor users on the team

### 1b. Personal/Machine-Local — Never Committed

| Layer | Location | Scope | What Goes Here |
|---|---|---|---|
| Global Claude Code | `~/.claude/CLAUDE.md` | All projects, all repos | Personal code style, preferred response format, personal tool shortcuts, "never add Co-Authored-By", language pref |
| Global Claude rules | `~/.claude/rules/*.md` | All projects | Topic-specific personal preferences (e.g., `~/.claude/rules/preferences.md`) |
| Global Cursor rules | Cursor Settings > Rules (User Rules) | All Cursor projects | Personal Cursor behavior, personal code style, Cursor shortcuts |
| Per-repo personal | `./CLAUDE.local.md` | Current repo only | Personal sandbox URLs, local token paths, personal test data for this repo |
| Private agent tooling | `claude-configs/` private repo | Per-project .claude/agents/ and .claude/skills/ | Personal subagents, skills that aren't team-approved |

**Exclusion mechanics:**
- `CLAUDE.local.md`: add to `.gitignore` (or use `/init` personal option — Claude Code does this automatically)
- Symlinked personal `.claude/agents/` and `.claude/skills/`: add to `.git/info/exclude` (NOT `.gitignore`) — `.git/info/exclude` is machine-local, never committed, invisible to teammates (Irina Scurtu, Apr 2026)
- Personal `.cursor/rules/` local entries: store in `~/.cursor/rules/` (user-level, not in repo)

---

## 2. Should a Shared Repo Reference a Personal KB? No.

The answer is unambiguous: **a committed file in a shared Bitbucket repo must never reference a personal private path or vault.**

Reasons:
1. **Path rot**: `~/Documents/SirvenOS/Catalist/` is valid on Jose's machine, nonexistent on any teammate's machine. Any agent running in CI or on another developer's checkout would fail to resolve the import.
2. **Privacy**: A committed `CLAUDE.md` or `AGENTS.md` that imports from a personal vault leaks the vault's existence and structure into the team's version history permanently.
3. **Coupling debt**: The shared repo would become dependent on a personal file that the team cannot audit, version, or update.
4. **Security surface**: MCP servers (Obsidian MCP) configured in committed `.mcp.json` files inside a repo create a team-wide MCP dependency. This is appropriate only for team-shared MCP servers, not personal ones.

### How to give a coding agent personal KB context without committing

Three safe patterns, in order of preference:

**Pattern A — Global personal CLAUDE.md import (zero repo footprint)**
In `~/.claude/CLAUDE.md`, add:
```markdown
@~/Documents/SirvenOS/Catalist/Research/02-agent-tooling-conventions/per-tool-agent-files.md
```
Claude Code triggers a one-time approval dialog per imported path. After approval, the content loads into every session on your machine, regardless of which repo you're in. No repo file is touched.

**Pattern B — CLAUDE.local.md import (per-repo, gitignored)**
In `./CLAUDE.local.md` (gitignored):
```markdown
# Personal KB context for this project
@~/Documents/SirvenOS/Catalist/Research/02-agent-tooling-conventions/per-tool-agent-files.md
```
Scoped to the current repo only. Invisible to teammates. The gitignore entry can be managed via `.git/info/exclude` to avoid even dirtying `.gitignore`.

**Pattern C — Obsidian MCP server, local MCP config (no repo footprint)**
Configure `obsidian-mcp-server` or `mcpvault` in `~/.claude/settings.json` (Claude Code's user MCP config) or Cursor's local settings. The agent can then query the vault via MCP tools as needed. This is the most powerful pattern — the agent gets live, queryable vault access rather than a static import — but requires the MCP server to be running locally. Never commit `.mcp.json` with a personal Obsidian MCP config to a shared repo.

---

## 3. Parent/Overlay Pattern Across Two Separate Trees

Within a single repo, the pattern is well-established (per `per-tool-agent-files.md`):

```
AGENTS.md          ← shared parent, cross-tool canonical
CLAUDE.md          ← Claude overlay: @AGENTS.md + Claude-specific additions
.cursor/rules/     ← Cursor overlay: glob-scoped MDC rules
```

**When the second tree is a separate vault (different filesystem path), this pattern does not extend across trees.**

- The vault is not a parent `AGENTS.md` to the repo's `CLAUDE.md`. There is no standard mechanism for cross-repo or cross-directory parent chaining via `@import` that would work on all machines.
- What IS independent vs. what syncs:

| Concern | Syncs automatically? | How |
|---|---|---|
| Team coding conventions | Yes, via committed AGENTS.md | Git |
| Personal code style | Yes, across all your machines | Dotfiles repo for `~/.claude/CLAUDE.md` and Cursor User Rules |
| Personal KB context injected into agent | No — machine-local only | `~/.claude/CLAUDE.md` imports or MCP config (not committed) |
| Personal agent skills for a shared repo | Via private `claude-configs/` repo + symlinks | Private git repo, `.git/info/exclude` to hide symlinks |
| Team Cursor rules | Yes, via committed `.cursor/rules/` | Git |
| Personal Cursor rules | Yes, across your machines | Cursor User Rules sync (Cursor's built-in sync, or dotfiles) |

The vault and the repo are always **independent trees that meet only inside the agent's in-memory context**, assembled from: (1) the team's committed files, (2) your personal global files, (3) optional MCP tools. The vault never becomes a structural parent of the repo's instruction files.

---

## 4. Concrete Recommendation for Jose

Jose's setup: Bitbucket repos at `~/Catalist/<repo>`, private Obsidian vault at `~/Documents/SirvenOS/Catalist/`, coding in Cursor + Claude Code.

### Step 1 — Each shared Bitbucket repo gets a committed `AGENTS.md`

```markdown
## <Repo name>

<One sentence project purpose.>

## Commands
- Build: `<exact command>`
- Test: `<exact command>`
- Lint: `<exact command>`

## Stack
- <Framework, versions, key choices>

## Structure
- `src/` — <what lives here>
- `<other stable paths>` — <what lives here>

## Conventions
- <Named exports only / default export policy>
- <Error response shape>
- <Migration naming convention>
- <etc — specific, verifiable, team-agreed>
```

Keep it under ~150 lines. No personal content. No vault references.

### Step 2 — `CLAUDE.md` in the same repo (team-shared Claude overlay)

```markdown
@AGENTS.md

## Claude Code
<!-- Claude-specific additions for the whole team -->
Use plan mode for changes under src/billing/.
```

If there are no Claude-specific team additions, a one-line `@AGENTS.md` is sufficient.

### Step 3 — Personal global layer: `~/.claude/CLAUDE.md`

```markdown
# Jose's personal global Claude preferences (applies to all repos)

## Style
- Respond concisely; no filler phrases
- Use TypeScript strict mode conventions
- Prefer named exports

## Workflow
- Never add Co-Authored-By: Claude to commits
- Confirm before running destructive commands

## Personal context
@~/Documents/SirvenOS/Catalist/Research/02-agent-tooling-conventions/per-tool-agent-files.md
```

This file is machine-local, applies to every Claude Code session across all repos, and is the right place for Jose's personal style and selective vault imports.

### Step 4 — Cursor User Rules (personal, not in any repo)

In Cursor Settings > Rules > User Rules:
```
- Always use TypeScript with strict mode
- Prefer named exports over default exports
- <other personal Cursor preferences>
```

These apply globally to all Cursor projects. Never committed to a repo.

### Step 5 — Per-repo personal escape hatch: `CLAUDE.local.md`

In `~/Catalist/<repo>/CLAUDE.local.md` (gitignored):
```markdown
# Personal local context for this repo only
Sandbox API base: http://localhost:3001
Personal test user: jose@sirven.xyz
```

Add to `.git/info/exclude` (not `.gitignore`):
```
echo "CLAUDE.local.md" >> ~/Catalist/<repo>/.git/info/exclude
```

### Step 6 — Personal agents/skills: private `claude-configs/` repo + symlinks

```bash
mkdir -p ~/claude-configs/<repo>/.claude/agents
mkdir -p ~/claude-configs/<repo>/.claude/skills
# Move personal agents/skills there, then symlink back:
ln -s ~/claude-configs/<repo>/.claude/agents ~/Catalist/<repo>/.claude/agents
echo ".claude/agents" >> ~/Catalist/<repo>/.git/info/exclude
echo ".claude/skills" >> ~/Catalist/<repo>/.git/info/exclude
```

Personal agents that are not team-approved stay in `~/claude-configs/`, versioned privately, invisible to Bitbucket.

### Step 7 — Obsidian MCP for richer KB access (optional)

Install `obsidian-mcp-server` or `mcpvault`. Configure in `~/.claude/settings.json`:
```json
{
  "mcpServers": {
    "obsidian": {
      "command": "node",
      "args": ["/path/to/obsidian-mcp-server/dist/index.js"],
      "env": { "VAULT_PATH": "/Users/jsirven/Documents/SirvenOS/Catalist" }
    }
  }
}
```
This gives Claude Code live, queryable access to the vault during sessions. No repo file references the MCP config — it lives entirely in `~/.claude/`.

---

## 5. The Full Decision Tree

```
"Should this go in a committed repo file?"

Is it a team convention everyone must follow?
  YES → AGENTS.md (or CLAUDE.md below @AGENTS.md import, or .cursor/rules/)
  NO  ↓

Is it personal style that applies to all your projects?
  YES → ~/.claude/CLAUDE.md or Cursor User Rules
  NO  ↓

Is it personal context specific to this repo?
  YES → CLAUDE.local.md (gitignored via .git/info/exclude)
  NO  ↓

Is it KB context from your Obsidian vault?
  YES → @import in ~/.claude/CLAUDE.md, or CLAUDE.local.md, or MCP server
  NEVER → a committed AGENTS.md, CLAUDE.md, or .cursor/rules/ file
```

---

## 6. Common Anti-Patterns to Avoid

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| Adding personal sandbox URLs to `AGENTS.md` | Teammates can't use your URLs; creates noise | `CLAUDE.local.md` |
| Committing `@~/Documents/SirvenOS/...` in `CLAUDE.md` | Breaks on every other machine; privacy leak | `~/.claude/CLAUDE.md` import |
| Adding `.claude/agents/` to `.gitignore` | Pollutes the team's gitignore; teammates see personal exclusion | `.git/info/exclude` |
| Committing personal `.cursor/rules/` for personal style | Teammates get your personal preferences; Cursor rule conflicts | Cursor User Rules |
| Committing `.mcp.json` with personal Obsidian MCP | Makes team dependent on your local MCP server | `~/.claude/settings.json` |
| Making the vault a structural parent of AGENTS.md | No cross-tree `@import` standard; breaks on CI and other machines | Vault context via global import or MCP only |
| Auto-generating `AGENTS.md` with `/init` | Bloated, generic, stale; ETH Zurich 2026 shows -3% task success vs human-written | Hand-write; < 150 lines; command-focused |

---

## Sources

- **Anthropic Claude Code official docs — Memory** (code.claude.com/docs/en/memory, 2026): canonical reference for CLAUDE.md hierarchy, CLAUDE.local.md gitignore behavior, `@import` syntax, `~/.claude/CLAUDE.md` global scope, `.claude/rules/` user-level rules.
- **Cursor Docs — Rules** (cursor.com/docs/rules, 2026): User Rules (global, Settings > Rules) vs. Project Rules (`.cursor/rules/*.mdc`, committed); `~/.cursor/rules/` for user-level rules.
- **Irina Scurtu — "Keep Your Claude Code Agents Out of the Team's Repo"** (irina.codes, Apr 2026): symlink pattern, private `claude-configs/` repo, `.git/info/exclude` vs `.gitignore` rationale, step-by-step setup.
- **DeployHQ — "CLAUDE.md, AGENTS.md & Copilot Instructions"** (deployhq.com, updated May 2026): `AGENTS.override.md` as Codex CLI's gitignored personal override; cross-tool landscape table; "AGENTS.md is committed and shared, AGENTS.override.md is gitignored and personal."
- **Matt Pocock / AI Hero — "A Complete Guide to AGENTS.md"** (aihero.dev, 2026): minimal AGENTS.md content (purpose + package manager + commands); progressive disclosure; instruction budget (~150-200 max reliable instructions); against auto-generation.
- **obsidian-mcp-server** (github.com/cyanheads/obsidian-mcp-server): MCP server enabling read/write/search of Obsidian vaults; path traversal protection; intended for local, user-level MCP config.
- **mcpvault / MCPVault** (mcp-obsidian.org, github.com/bitbonsai/mcpvault): universal AI bridge for Obsidian vaults via MCP; Claude, ChatGPT, Cursor compatible.
- **HN — AGENTS.md open format thread** (news.ycombinator.com/item?id=44957443): practitioner discussion on team vs. personal conventions, personal overrides, file size discipline.
- **ETH Zurich AGENTbench** (arXiv 2602.11988, Feb 2026 — cited in per-tool-agent-files.md): auto-generated context files reduced task success -3% vs. no file; human-written gave +4%; all context files raised inference cost 20%+.
