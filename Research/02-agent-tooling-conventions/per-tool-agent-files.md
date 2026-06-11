---
title: "Per-Tool Agent Instruction Files — CLAUDE.md, AGENTS.md, Cursor Rules"
type: research
status: research-complete
updated: 2026-06-08
topic_cluster: agent-tooling-conventions
source_type: synthesis
related:
  - "../01-agent-context-engineering/research-agentsmd.md"
  - "../01-agent-context-engineering/research-anthropic.md"
tags:
  - AGENTS.md
  - CLAUDE.md
  - Cursor
  - multi-tool
  - context-engineering
  - per-tool-files
---

# Per-Tool Agent Instruction Files: CLAUDE.md, AGENTS.md, Cursor Rules

**TL;DR** — AGENTS.md has become the cross-tool open standard (Linux Foundation, 60k+ repos, 20+ tools) but Claude Code does NOT natively read it. The correct multi-tool pattern is: AGENTS.md as single source of truth, with a minimal CLAUDE.md that imports it via `@AGENTS.md`, and Cursor `.mdc` rules for glob-scoped activation that AGENTS.md cannot express. Symlinks work but have Windows caveats; the `@import` syntax is safer. Keep every file under ~200 lines. Auto-generated files actively hurt performance (ETH Zurich, Feb 2026). One key claim circulating widely — "Claude Code reads AGENTS.md as a fallback" — is **wrong** per official docs and 800-hour practitioner field testing.

---

## TL;DR (signal-first — read this, rest is JIT)

1. **AGENTS.md is the standard; Claude Code needs a bridge.** Claude Code reads CLAUDE.md only. Use `@AGENTS.md` as the first line of CLAUDE.md (preferred, Windows-safe) or a symlink (`ln -s AGENTS.md CLAUDE.md`). This is the #1 unmet feature request in the Claude Code tracker (5,200+ reactions, issue #6235). Native support not yet shipped as of 2026-06-08.
2. **Per-tool overlays beat one merged file** for tool-specific features. Cursor's `.cursor/rules/*.mdc` frontmatter (globs, `alwaysApply`, agent-decided) has no equivalent in AGENTS.md — these belong in Cursor's native format. CLAUDE.md's 3-layer memory hierarchy (global/project/local) has no equivalent in AGENTS.md. Keep shared narrative in AGENTS.md; put tool-specific mechanics in tool-native files.
3. **Short, human-written files outperform long auto-generated ones.** ETH Zurich AGENTbench study (arXiv 2602.11988, 138 tasks, 4 models): LLM-generated context files reduced task success by ~3% vs no file; human-written files gave +4%. All context files increased inference cost 20%+. HN consensus: keep it under ~200 lines, commands/conventions only, no structural code description.

---

## 1. Landscape: What Each Tool Reads

As of June 2026:

| File | Primary Tool | Also Read By | Format | Hierarchy |
|---|---|---|---|---|
| `CLAUDE.md` | Claude Code | Claude Code only | Markdown | Global `~/.claude/` → project → subdirectory (lazy) |
| `CLAUDE.local.md` | Claude Code | Claude Code only | Markdown | Same session as CLAUDE.md; gitignored; personal overrides |
| `AGENTS.md` | Codex CLI | Cursor, Copilot, Gemini CLI, Aider, Windsurf, Zed, Warp, Amp, Factory, Cline, 20+ others | Markdown | Nearest-file-wins walking up directory tree |
| `AGENTS.override.md` | Codex CLI | Codex only | Markdown | Gitignored local-only Codex overrides (alongside AGENTS.md) |
| `.cursor/rules/*.mdc` | Cursor | Cursor only | MDC (Markdown + YAML frontmatter) | Central dir; glob-scoped via frontmatter |
| `.cursorrules` | Cursor (legacy) | Cursor only | Plain text | Project root; deprecated; no globs/frontmatter |
| `.github/copilot-instructions.md` | GitHub Copilot | Copilot only | Markdown | Single file + optional `.github/instructions/*.instructions.md` with `applyTo:` glob |
| `GEMINI.md` | Gemini CLI | Gemini CLI only | Markdown | Global `~/.gemini/` → project → subdirectory |
| `.windsurfrules` / `.windsurf/rules/` | Windsurf | Windsurf only | Markdown | Legacy single-file or directory; 6k char per file, 12k total cap |

**Key clarification on Claude Code + AGENTS.md:** Claude Code does NOT read AGENTS.md as a fallback. Multiple third-party guides claim this; it is not in the official docs (checked 2026-06-03, operator field guide by yurukusa, 800+ hours testing). The claim likely originated from imprecise paraphrasing of the `/init` behavior: `/init` reads AGENTS.md when generating a CLAUDE.md for the first time, but Claude Code does not continuously read AGENTS.md at runtime.

---

## 2. The Symlink vs Import Pattern

### The `@AGENTS.md` import (recommended default)

Create a CLAUDE.md that contains only:

```markdown
@AGENTS.md

## Claude Code
<!-- Claude-specific additions here that other tools should not see -->
Use plan mode for changes under src/billing/.
```

- Works on all platforms including Windows (no Admin/Developer Mode needed)
- Cannot drift — there is only one real file
- Triggers a one-time approval dialog in Claude Code; once approved, loads silently
- Claude-specific additions go below the import; other tools never see them

### Symlink (`ln -s AGENTS.md CLAUDE.md`)

```bash
ln -s AGENTS.md CLAUDE.md
git add CLAUDE.md   # git tracks symlinks natively
```

- Simpler if you need no Claude-specific additions
- Windows requires `git config core.symlinks true` + Admin/Developer Mode; prefer import there
- Git handles symlinks across platforms if `core.symlinks=true` (set by default in modern Git for Windows)
- SSW Rules (Gordon Beeming, Daniel Mackay) document this as their team standard

### When symlink hurts

- When you need Claude-specific content that should NOT appear in AGENTS.md (tool-specific MCP references, plan-mode rules, Claude hooks configuration)
- When AGENTS.md is auto-generated and should stay pristine
- On Windows teams without Developer Mode

### Alternative patterns (escalating complexity)

Operator field guide by yurukusa (2026-06-03, MIT, 800hr field test) documents 5 patterns beyond the import:

| Pattern | When | Tradeoff |
|---|---|---|
| Pre-commit hook mirror | Two real files needed; Windows team | Requires hook install per machine |
| SessionStart hook merge | AGENTS.md is auto-generated or has irrelevant content | Machine-local; needs install |
| Per-project direnv routing | Polyrepo with inconsistent canonical sources | Requires direnv |
| CI drift detection script | Team or OSS; want drift visible in CI | Config per repo |

---

## 3. Tool-Specific Quirks

### Claude Code (CLAUDE.md)

- **3-layer load order**: Managed policy (`/Library/Application Support/ClaudeCode/CLAUDE.md`) → user (`~/.claude/CLAUDE.md`) → project (`./CLAUDE.md` or `./.claude/CLAUDE.md`) → local (`./CLAUDE.local.md`). All concatenated; project-closer = read last (higher specificity).
- **Subdirectory CLAUDE.md**: Loaded lazily (only when Claude reads files in that subdirectory), NOT at startup. Important: nested files do not re-inject after `/compact` — only project-root CLAUDE.md survives compaction.
- **`.claude/rules/` directory**: Path-specific rules with YAML frontmatter (`paths:` globs). Load only when matching files are opened. Analogous to Cursor MDC but within Claude Code's own ecosystem.
- **`@import` syntax**: `@path/to/file` expands inline at session start. Max recursion depth: 4 hops. Both relative and absolute paths work. Imported files load in full at launch (does not reduce context vs putting content inline).
- **Auto memory**: Claude writes to `~/.claude/projects/<repo>/memory/MEMORY.md` automatically. First 200 lines / 25KB loaded every session. Topic files (e.g., `debugging.md`) loaded on-demand. Machine-local; not shared across machines.
- **`/memory` command**: Lists all loaded CLAUDE.md, rules, and auto-memory files. Toggle auto-memory. Edit files in-session.
- **Size guidance**: Target < 200 lines per file. Longer files reduce adherence; Claude Code system prompt already consumes ~50 of the ~150–200 instruction budget. Soft limit only — no truncation — but adherence degrades.
- **Emphasis markers work**: Anthropic docs confirm `IMPORTANT`, `YOU MUST`, `NEVER` measurably increase adherence vs plain prose.
- **`claudeMdExcludes`**: In large monorepos, add to `.claude/settings.local.json` to skip ancestor CLAUDE.md files from other teams.

### Codex CLI (AGENTS.md)

- **Discovery**: Walks root → CWD, checking each level for AGENTS.md. Nearest to CWD loaded. NOT nearest-file-wins upward like Claude Code — it walks downward from root.
- **`AGENTS.override.md`**: Gitignored local-only overrides. Lives alongside AGENTS.md at any level. The official mechanism for machine-specific or personal tweaks. **Commit AGENTS.md; gitignore AGENTS.override.md.**
- **Size hard limit**: `project_doc_max_bytes` in `~/.codex/config.toml` (default: 64 KiB per file). Content past cap is **silently truncated**. This is a real footgun — oversized files stop working without any error.
- **`project_doc_fallback_filenames`**: Config knob to try alternate filenames if no AGENTS.md found (e.g., `["TEAM_GUIDE.md", ".agents.md"]`).
- **Monorepo**: OpenAI's own monorepo uses 88 AGENTS.md files. Nearest-file-wins when agent edits a file. No merging — the closest file wins entirely.

### Cursor (`.cursor/rules/*.mdc`)

- **4 activation modes** via YAML frontmatter:
  - `alwaysApply: true` → loaded on every request (equivalent to always-on system prompt addition)
  - `alwaysApply: false` + `globs:` → auto-attached when matching files are open
  - `alwaysApply: false` + `description:` only (no globs) → agent-decided (agent reads description and pulls rule if relevant)
  - Manual → only via `@rule-name` in chat
- **Legacy `.cursorrules`**: Still supported, no deprecation breaking change yet, but no frontmatter/globs/modes. Migrate at leisure.
- **Cursor also reads AGENTS.md**: As of 2026, Cursor reads a root-level AGENTS.md natively. Use `.cursor/rules/*.mdc` only for glob-scoped activations that AGENTS.md cannot express.
- **Rule porter tool**: `rule-porter` CLI converts `.mdc` rules to AGENTS.md / CLAUDE.md / Copilot format, but warns: MDC frontmatter semantics (globs, alwaysApply) have no equivalent in the other formats — converting is not just copy-paste.
- **Recommended pattern for Cursor + other tools**: Keep AGENTS.md at root for shared instructions; use `.cursor/rules/` only for Cursor-specific scoped rules.

### GitHub Copilot

- **Primary file**: `.github/copilot-instructions.md` (repo-wide)
- **Scoped files**: `.github/instructions/*.instructions.md` with `applyTo:` glob frontmatter (analogous to Cursor MDC globs)
- **Also reads AGENTS.md** natively since late 2025; AGENTS.md is lower priority than `.github/copilot-instructions.md`
- **Symlink pattern**: `ln -s ../AGENTS.md .github/copilot-instructions.md` works for keeping PR reviews consistent (SSW Rules)

### Windsurf

- Character limits: 6,000 chars per individual rule file; 12,000 chars total across all rules
- Current format: `.windsurf/rules/*.md` (replaces legacy `.windsurfrules`)
- Also reads AGENTS.md natively since 2026 (confirmed via Windsurf docs)

---

## 4. Multi-Tool Pattern (the recommended layout)

For a repo used by Cowork/Claude Code + Cursor + Codex/other:

```
your-repo/
├── AGENTS.md                    ← Single source of truth (shared narrative, commands, conventions)
├── AGENTS.override.md           ← Gitignored; local Codex overrides
├── CLAUDE.md                    ← One line: "@AGENTS.md" + Claude-specific additions below
├── CLAUDE.local.md              ← Gitignored; personal Claude Code overrides (sandbox URLs, etc.)
├── .claude/
│   ├── CLAUDE.md                ← Optional: alternative project CLAUDE.md location
│   └── rules/
│       ├── billing.md           ← Path-scoped: paths: ["src/billing/**"]
│       └── api-design.md        ← Path-scoped: paths: ["src/api/**/*.ts"]
├── .cursor/
│   └── rules/
│       ├── frontend.mdc         ← alwaysApply: false; globs: ["src/components/**/*.tsx"]
│       └── backend.mdc          ← alwaysApply: false; globs: ["src/api/**/*.ts"]
├── .github/
│   └── copilot-instructions.md  ← Optional: symlink to ../AGENTS.md OR separate Copilot focus
└── .gitignore                   ← includes: AGENTS.override.md, CLAUDE.local.md
```

**What goes where:**

| Content | File |
|---|---|
| Build/test commands, tech stack, naming conventions, do-not-touch list | AGENTS.md |
| MCP server references, plan-mode rules, Claude-specific hooks | CLAUDE.md (below `@AGENTS.md`) |
| Personal sandbox URLs, local DB credentials, machine-specific paths | CLAUDE.local.md (gitignored) |
| Glob-triggered rules (only load when editing matching files) | `.cursor/rules/*.mdc` or `.claude/rules/*.md` |
| Local Codex overrides | AGENTS.override.md (gitignored) |

---

## 5. Progressive Disclosure: What Goes in the Root vs Elsewhere

The "ball of mud" anti-pattern: every time an agent does something wrong, a new rule is added. After months this becomes an unmaintainable, contradictory file that actively hurts performance.

**The progressive disclosure model** (Matt Pocock / AIHero, Kaushik Gopal / kau.sh):

Root AGENTS.md / CLAUDE.md → reference to `docs/TYPESCRIPT.md` → reference to `docs/TESTING.md`

Root file contains only:
- One-sentence project description
- Package manager (if not npm)
- Non-standard build/typecheck commands
- "For TypeScript conventions, see docs/TYPESCRIPT.md"

Domain-specific files loaded on-demand or via reference. Claude Code `.claude/rules/` with `paths:` frontmatter is the formal mechanism for this in Claude Code's ecosystem.

**Monorepo pattern**: Root AGENTS.md for global defaults, subdirectory AGENTS.md per package. Claude Code: use `claudeMdExcludes` to prevent loading other teams' files. Codex: nearest-file-wins (no merging).

---

## 6. What NOT to Put in These Files

| Anti-pattern | Why | Alternative |
|---|---|---|
| Code style rules ("use 2-space indentation") | LLMs can't enforce formatting reliably; eats instruction budget | ESLint/Prettier/formatters |
| File path descriptions ("auth lives in src/auth/handlers.ts") | Paths change; stale paths actively mislead agents (worse than nothing) | Describe capabilities, not file locations |
| Full API documentation | Token waste | Link to docs/; use `llms.txt` on external sites |
| Business logic architecture descriptions | Agent can explore the codebase; description is stale and token-costly | Agent reads source directly |
| Auto-generated content (from `/init` or similar) | ETH Zurich: -3% task success; +20% inference cost | Write by hand; use `/init` as a starting draft, then prune heavily |
| Secrets, API keys, env vars | Committed to git; readable by any tool | .env + secret manager |
| Task-specific instructions | Belongs in the prompt, not persistent config | Prompt directly |
| "Write clean code", "follow best practices" | Vague; zero signal | Be specific or omit |
| 500+ line files | Codex silently truncates; Claude adherence degrades | Split with progressive disclosure |

### What to keep private (not commit)

| File | Why private |
|---|---|
| `CLAUDE.local.md` | Personal overrides, sandbox URLs, machine-specific settings |
| `AGENTS.override.md` | Local Codex overrides; machine-specific paths |
| `~/.claude/CLAUDE.md` | Personal global preferences across all projects |
| `.claude/settings.local.json` | Machine-local settings (claudeMdExcludes, etc.) |
| Auto-memory files (`~/.claude/projects/*/memory/`) | Machine-local; Claude-written; not portable |

---

## 7. The ETH Zurich Study — Calibrated Interpretation

**Study**: "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?" — Gloaguen, Mündler, Müller, Raychev, Vechev (ETH Zurich + LogicStar.ai), arXiv 2602.11988, February 2026.

**Method**: AGENTbench — 138 real-world Python software engineering tasks from niche repositories. 4 frontier models. 3 conditions: no context file, LLM-generated context file, human-written context file.

**Findings**:
- LLM-generated context files: **-3% task success rate**, **+20% inference cost**
- Human-written context files: **+4% task success rate**, **+20% inference cost**
- All context files: increased step count to complete tasks

**HN discourse consensus** (threads 48441589, 47295454, 44957443):
- The -3% finding applies to *median public GitHub AGENTS.md* — often auto-generated, stale, or describing code structure rather than providing commands
- "A bad AGENTS.md can be very bad; they rot quickly — human curation is essential" (nikcub)
- "The main benefits are inherently opposed to characteristics of median public-repo AGENTS.md" (deaux)
- Practitioners with hand-curated command-focused files report clear positive impact
- HN user RugnirViking: "Telling it 'use xyz version of java, use gradle, run tests with this command' is really important instead of letting it fumble every time"
- The +4% from human-written files is modest but directional; the real value may be in preventing consistent repeated mistakes rather than improving average task score

**Calibrated conclusion**: The study warns against auto-generated and stale context files. It does not debunk well-maintained, concise, human-written files. Keep files short, command-focused, and regularly pruned.

---

## 8. Community Signal & Who's Saying What

### Hacker News patterns (threads 44957443, 48441589, 47295454, 46398957)

- Skeptics: "It's just a prompt prepend. Long preambles benefit cloud AI companies, not users." (dofm); "putting 'you're an expert X' is shaman bone-burning" (wiseowise)
- Practitioners: "Yes — commands and terminology blobs, not code descriptions" (RugnirViking, nikcub)
- The cargo-culting concern is real: many files copy-paste generic templates without curating for their project
- Emerging consensus: shorter is better, commands over descriptions, progressive disclosure > monolithic file

### X/Twitter patterns

- @rasbt (Sebastian Raschka, ML researcher): shared the ETH Zurich study, sparked HN thread 48441589
- @psawers (Paul Sawers, Tessl): Anthropic's Claude Code absence from AGENTS.md adoption noted as "Anthropic-sized elephant in the room" (Sept 2025, tessl.io)
- General: practitioners who maintain their files report clear improvement; those who let agents auto-generate report neutral or negative results

### Practitioner patterns (kau.sh, aihero.dev, deployhq, SSW Rules)

- Kaushik Gopal (kau.sh): single source-of-truth repo + Makefile for symlinks; 2-level setup (user-global + per-project)
- Matt Pocock (aihero.dev): progressive disclosure refactor prompt; "ideal AGENTS.md is as small as possible"; points-elsewhere pattern
- SSW Rules (Gordon Beeming, Daniel Mackay, Brady Stroud): symlink-first; `.agents/skills/ → .claude/skills/`
- DeployHQ (Alex M): "A focused 50-line file outperforms a sprawling 1,000-line one"

---

## 9. Actionable Recommendations for Cowork + Cursor + Claude Code KB/Repo

1. **Make AGENTS.md the single source of truth.** Write shared conventions, build commands, and project structure once in AGENTS.md. Keep it under 200 lines. No auto-generation.

2. **Bridge to Claude Code with `@AGENTS.md` import.** Create CLAUDE.md containing `@AGENTS.md` as the first line. Add Claude-specific content below: MCP server references, plan-mode rules for sensitive directories, any Claude Code hooks. This avoids Windows symlink issues and prevents drift structurally.

3. **Use Cursor `.mdc` rules only for glob-scoped additions.** AGENTS.md cannot express "only load these rules when editing TypeScript in `src/api/`". Put those in `.cursor/rules/api.mdc` with `globs: ["src/api/**/*.ts"]` and `alwaysApply: false`. Keep AGENTS.md portable; put Cursor-specific activation logic in MDC.

4. **Gitignore the private files.** Ensure `CLAUDE.local.md`, `AGENTS.override.md`, and `.claude/settings.local.json` are in `.gitignore`. These are the correct mechanism for machine-specific and personal overrides — do not commit them.

5. **Use progressive disclosure for large content.** Instead of a 500-line CLAUDE.md, use `.claude/rules/billing.md` with `paths: ["src/billing/**"]`. That rule only loads into context when Claude is editing billing files. For Cursor, same pattern via MDC.

6. **Maintain manually; prune quarterly.** Stale context is worse than no context (ETH Zurich). Remove any line that describes file structure (paths change), any instruction a linter handles, and any task-specific instruction that belongs in a prompt. Add a line when Claude makes the same mistake twice.

---

## Sources

| Source | URL | Type | Signal strength |
|---|---|---|---|
| Official Claude Code memory docs | https://code.claude.com/docs/en/memory | Official docs | Authoritative |
| "CLAUDE.md, AGENTS.md & Copilot Instructions" — DeployHQ (Alex M, updated May 2026) | https://www.deployhq.com/blog/ai-coding-config-files-guide | Industry blog | High — comprehensive, well-structured |
| "Do you symlink your AGENTS.md?" — SSW Rules (Beeming, Mackay, Stroud) | https://www.ssw.com.au/rules/symlink-agents-to-claude | Practitioner rules | High — concrete, opinionated, team-tested |
| "The rise of AGENTS.md" — Tessl / Paul Sawers (Sept 2025) | https://tessl.io/blog/the-rise-of-agents-md-an-open-standard-and-single-source-of-truth-for-ai-coding-agents/ | Industry journalism | Medium-high — good context on adoption/history |
| "Keep your AGENTS.md in sync" — Kaushik Gopal (kau.sh) | https://kau.sh/blog/agents-md/ | Practitioner blog | High — real workflow, Makefile, multi-tool |
| "A Complete Guide to AGENTS.md" — Matt Pocock (aihero.dev) | https://www.aihero.dev/a-complete-guide-to-agents-md | Practitioner/educator | High — progressive disclosure model, instruction budget |
| "AGENTS.md vs CLAUDE.md vs Cursor Rules" — Codersera (May 2026) | https://codersera.com/blog/agents-md-vs-claude-md-vs-cursor-rules-comparison-2026/ | Industry blog | High — comprehensive format comparison table |
| "Does Claude Code read AGENTS.md? No." — yurukusa (GitHub Gist, updated 2026-06-03) | https://gist.github.com/yurukusa/d36197848911f025add142abefcde685 | Operator field guide | Very high — adversarially verified, 800hr field test, debunks fallback myth |
| AGENTS.md × Claude Code interop (GitHub issue #6235) | https://github.com/anthropics/claude-code/issues/6235 | Community signal | High — 5,200+ reactions; shows real operator pain |
| ETH Zurich AGENTbench study — arXiv 2602.11988 (Feb 2026) | https://arxiv.org/abs/2602.11988 | Academic paper | High (caveated) — 138 tasks, 4 models; but median public-repo bias |
| HN "Do agents.md files help?" (thread 48441589) | https://news.ycombinator.com/item?id=48441589 | Community discourse | High — active practitioner debate, calibrates ETH study |
| HN "AGENTS.md open format" (thread 44957443) | https://news.ycombinator.com/item?id=44957443 | Community discourse | Medium — broader adoption/standardization discussion |
| Anti-patterns guide — Simon Willison (March 2026) | https://simonwillison.net/guides/agentic-engineering-patterns/anti-patterns/ | Practitioner | High — Simon is authoritative; PR review anti-pattern |
