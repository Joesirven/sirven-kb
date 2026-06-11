---
title: "AGENTS.md Best Practices — Standard, Cascade, KB Implications"
type: research
status: research-complete
updated: 2026-06-07
topic_cluster: agent-context-engineering
source_url: "https://agents.md/"
source_type: docs
as_of: 2026-06-07
revisit_when: "2026-12-01 or when AGENTS.md standard publishes a major revision"
related:
  - "research-anthropic.md"
  - "research-practitioners.md"
  - "../02-agent-tooling-conventions/per-tool-agent-files.md"
tags:
  - AGENTS.md
  - cascade
  - monorepo
  - context-engineering
---

# AGENTS.md Best Practices — Research Notes
*Researched: 2026-06-07 | Scope: Standard overview + nested/monorepo cascade + KB implications*

---

## 1. What AGENTS.md Is

AGENTS.md is an open Markdown standard (stewarded by the Agentic AI Foundation under the Linux Foundation, donated by OpenAI, Amp, Google, Cursor, Factory) that provides a **dedicated, predictable file where humans give AI coding agents project context and operational instructions**.

- Think of it as a "README for agents" — separate from README.md to keep human docs clean
- It sits at the top of the conversation, just below the system prompt, on **every request**
- Standard since August 2025; 60,000+ open-source projects use it
- Format: plain Markdown, no required fields, no schema

**Key distinction:** AGENTS.md is *operational policy*, not human documentation. It contains commands, constraints, and verifiable "done" criteria — not prose explanations.

---

## 2. Cross-Tool Compatibility

| Tool | Native file | Reads AGENTS.md? | Notes |
|---|---|---|---|
| Codex CLI (OpenAI) | AGENTS.md | Yes (native) | Full hierarchy + `AGENTS.override.md` |
| Cursor | `.cursor/rules/*.mdc` | Yes (native) | Auto-discovered in root + subdirs |
| GitHub Copilot | `.github/copilot-instructions.md` | Yes (native) | Coding agent; VS Code needs opt-in flag |
| Amp | AGENTS.md | Yes (native) | Co-created standard; backward-compatible with `AGENT.md` |
| Windsurf | `.windsurfrules` | Yes (native) | Case-insensitive match |
| Gemini CLI | `GEMINI.md` | Configurable | Add `"fileName": "AGENTS.md"` in `.gemini/settings.json` |
| **Claude Code** | **CLAUDE.md** | **No** | Separate format; symlink if needed: `ln -s AGENTS.md CLAUDE.md` |
| Aider | `CONVENTIONS.md` | Manual | Requires `--read AGENTS.md` flag |
| Jules, goose, opencode, Zed, Warp, Devin, Junie, RooCode, Kilo, Phoenix | varies | Yes | All support AGENTS.md natively |

**Casing note:** Tools use case-insensitive matching (e.g., Windsurf). Safe to use `AGENTS.md` (all-caps) universally; `AGENT.md` (singular) is a deprecated alias.

**Multi-tool teams:** Maintain one canonical source (`AGENTS.md`), then use a post-checkout hook or symlinks to sync tool-specific files (CLAUDE.md, `.cursor/rules/*.mdc`). Parallel copies diverge.

---

## 3. Cascade / Merge Mechanics (Codex CLI canonical behavior)

Codex builds an **instruction chain** once per session (not lazily, not cached mid-session). Editing files mid-session requires a restart.

### Lookup order (Codex CLI)

```
1. Global scope — ~/.codex/ (or $CODEX_HOME):
   - AGENTS.override.md  ← if present, only this is used at this level
   - AGENTS.md           ← used only if override absent
   (at most one file at this level)

2. Project scope — git root → current working directory:
   For each directory on the path down to cwd:
     - AGENTS.override.md
     - AGENTS.md
     - project_doc_fallback_filenames (e.g., TEAM_GUIDE.md)
   (at most one file per directory)

3. If no git root found: only check cwd.
```

### Concatenation (not replacement)

Files are **joined with blank lines, root-first, leaf-last**. The entire chain is present in context simultaneously. "Closest wins" means later text overrides earlier text for conflicting instructions — it does not mean other files are dropped.

```
~/.codex/AGENTS.md          ← loaded first
repo-root/AGENTS.md         ← concatenated next
apps/web/AGENTS.md          ← concatenated last (highest effective precedence)
```

Only files *on the path from git root to cwd* are loaded. Sibling directories' files are never loaded.

### AGENTS.override.md (Codex-specific)

At any level, `AGENTS.override.md` **replaces** (does not extend) the `AGENTS.md` at that same level. Use cases: release freezes, security constraints, personal dev preferences that shouldn't be committed. Recommendation: add `**/AGENTS.override.md` to `.gitignore`.

### Size cap

`project_doc_max_bytes` defaults to **32 KiB**. Codex stops adding files once the combined chain reaches the cap (in lookup order). A bloated global file can starve repo-specific files. Keep global file ≤ 5 KiB. Raise the cap in `~/.codex/config.toml` if needed (e.g., `65536` for 64 KiB).

### Fallback filenames

Configure in `~/.codex/config.toml`:
```toml
project_doc_fallback_filenames = ["TEAM_GUIDE.md", ".agents.md"]
```
Codex checks `AGENTS.override.md` → `AGENTS.md` → fallbacks, in that order, per directory.

---

## 4. Progressive Disclosure (Root Points to Deeper Files)

The root `AGENTS.md` should be minimal and act as an **index**, pointing to deeper files for domain-specific rules. Agents navigate documentation hierarchies efficiently — they don't need everything upfront.

**Pattern:**
```markdown
# Root AGENTS.md
This is a monorepo for web services and CLI tools. Use pnpm workspaces.

For TypeScript conventions, see docs/TYPESCRIPT.md
For API design patterns, see docs/API_CONVENTIONS.md
```

This keeps the token budget available for task-specific work. The deeper files load only when the agent navigates there or explicitly references them.

A discoverable resource tree can also go multiple levels deep:
```
docs/
├── TYPESCRIPT.md      → references TESTING.md
├── TESTING.md         → references specific test runners
└── BUILD.md           → references esbuild config
```

---

## 5. Conciseness and Token Budget

Every token in AGENTS.md is loaded on **every request**, regardless of relevance.

- Frontier thinking models follow ~150–200 instructions reliably; smaller/non-thinking models fewer
- **Target:** Each file under 50 lines; total file under 150 lines; total chain under 32 KiB
- The ideal AGENTS.md is "as small as possible" — not comprehensive

**Anti-patterns that bloat without benefit:**
- Auto-generated files ("initialization scripts flood files with things useful for most scenarios")
- Accumulating reactive rules every time the agent does something wrong
- Documenting file paths (they change; describe capabilities instead)
- Style guides without enforcement commands

**Stale documentation poison:** AI agents read documentation on every request. Unlike humans, they can't be skeptical of outdated docs. Stale paths, renamed APIs, or old conventions actively mislead. Document domain concepts (stable) over file paths (volatile).

---

## 6. What Actually Changes Agent Behavior

### Works

- **Command-first instructions** with exact invocations and exit-code verification
- **Closure definitions** ("A task is complete when ALL of the following pass: 1. `ruff check .` exits 0...")
- **Task-organized sections** (`## When Writing Code`, `## When Reviewing Code`, `## When Releasing`)
- **Escalation rules** ("If tests fail after 3 attempts: stop and report")
- **Explicit "Never" lists** (prevents destructive workarounds)
- **MCP tool guidance** (which server for which task, what's off-limits)

### Reliably ignored

- Prose paragraphs without commands
- Ambiguous directives ("be careful," "handle errors gracefully," "where possible")
- Contradictory priorities without explicit ordering (agents silently skip verification when stuck)
- Style guides without enforcement linter commands

**Test:** Ask the agent "What is your definition of done?" — if it can't reproduce your build commands verbatim, the instructions aren't being retained (file too verbose, too vague, or not discovered).

---

## 7. Monorepo Structure — Canonical Pattern

```
repo-root/
├── AGENTS.md                  # Universal: PR conventions, security rules, monorepo navigation
├── apps/
│   ├── web/
│   │   └── AGENTS.md          # Next.js / frontend conventions
│   └── api/
│       └── AGENTS.md          # Backend / API conventions
├── packages/
│   ├── ui/
│   │   └── AGENTS.md          # Design system rules
│   └── shared-types/
│       └── AGENTS.md          # Type-gen workflow
└── infra/
    └── AGENTS.md              # Terraform style, secret handling
```

When working in `apps/web/components/`, the chain loaded is:
`~/.codex/AGENTS.md` → `repo-root/AGENTS.md` → `apps/web/AGENTS.md`

`apps/api/AGENTS.md` and `packages/ui/AGENTS.md` are **not loaded** — they're on a different path. This is by design. Context is scoped to the work at hand.

**Real-world scale:** The OpenAI Codex repository itself uses 88 AGENTS.md files across its monorepo.

---

## 8. Known Failure Patterns

| Failure | Cause | Fix |
|---|---|---|
| Agent ignores rules | Rules are vague prose with no commands | Replace with exact shell commands + exit-code checks |
| Nested rules silently dropped | 32 KiB cap hit by bloated global file | Slim global file to ≤ 5 KiB; raise cap if needed |
| Cross-service rule pollution | `packages/ui/AGENTS.md` contains backend rules | Scope each file strictly to its directory's domain |
| "Done" without verification | No closure definition | Add explicit "Definition of Done" section with commands |
| Agent improvises destructively | No escalation rules | Add "When Blocked" section with stop conditions and "Never" list |
| Instructions stale mid-session | Edits not picked up | Restart session; chain is built once per run |
| Contradictory priorities | Unordered conflicting rules | Number priorities explicitly |
| Parallel tool copies drift | CLAUDE.md and AGENTS.md maintained separately | Single canonical source + symlink/hook to sync |

---

## 9. Writing Priority Order (Start Here)

Build AGENTS.md in this order — each layer depends on the previous:

1. **Build and test commands** — agent can't work without these
2. **Definition of Done** — prevents false "I think I'm done" completions
3. **Escalation rules** — prevents destructive workarounds when blocked
4. **Task-organized sections** — reduces irrelevant parsing per task
5. **Directory scoping** (monorepos) — isolates service-specific rules

Style preferences come last, if at all. Most AGENTS.md files fail because they start with style guidance and never reach commands.

---

## 10. What Each Directory Level Should Contain (Root vs. Child)

### Global scope (`~/.codex/AGENTS.md`)
- Personal working agreements that apply everywhere (e.g., preferred package manager, personal commit style)
- Must be ≤ 5 KiB to avoid starving project files under the 32 KiB cap
- Use `AGENTS.override.md` here for temporary personal overrides (gitignored)

### Repository root (`AGENTS.md`)
- One-sentence project/monorepo purpose
- Monorepo navigation hints (how to find packages, what `pnpm` commands are cross-cutting)
- Shared tools and package manager (if not npm)
- Cross-cutting PR/commit conventions
- Security rules that apply everywhere (no secrets in code, branching strategy)
- Cross-package contracts (shared types, RPC schemas, error codes)
- **Pointers** to deeper files for domain-specific guidance (`For TypeScript, see docs/TYPESCRIPT.md`)
- Should NOT include: stack-specific conventions, package-specific test commands, anything that doesn't apply to every task in the repo

### Package / service level (e.g., `apps/api/AGENTS.md`)
- Package purpose (one sentence)
- Language and framework conventions for this subtree
- Test discipline specific to this stack (`pytest -v`, `pnpm vitest run`)
- "Don't touch" list (vendored code, generated artifacts specific to this package)
- MCP tool guidance relevant to this service
- Should NOT include: root-level cross-cutting rules (those are inherited), other packages' conventions

### Sub-directory / feature level (e.g., `services/payments/AGENTS.override.md`)
- Use sparingly — only when a subdirectory has requirements that override the package defaults
- Security-sensitive areas (payment processing, auth, PII handling) that supersede parent rules
- Use `AGENTS.override.md` (not `AGENTS.md`) to signal intentional replacement, not extension
- Include explicit "Never" lists for this domain (e.g., "Never rotate API keys without notifying security channel")

### Gitignored personal layer (`AGENTS.override.md` or `AGENTS.local.md`)
- Personal preferences (formatting, verbosity, preferred libraries)
- Branch/task-specific temporary overrides
- Should never be committed; survives only for the duration of local work

### Rule of thumb per level:
> **Root:** why the project exists + shared contracts  
> **Package:** how this stack works  
> **Sub-directory:** what's off-limits here  
> **Personal:** how you prefer to work

---

## Sources

- [agents.md — Official Standard Site](https://agents.md/)
- [OpenAI Codex: Custom instructions with AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
- [CodeGateway: AGENTS.md Hierarchy Playbook 2026](https://www.codegateway.dev/en/blog/agents-md-playbook-2026)
- [AIHero / Matt Pocock: A Complete Guide to AGENTS.md](https://www.aihero.dev/a-complete-guide-to-agents-md)
- [Blake Crosley: AGENTS.md Patterns — What Actually Changes Agent Behavior](https://blakecrosley.com/blog/agents-md-patterns)
- [GitHub Issue #53 — agentsmd/agents.md: Multiple files in monorepo](https://github.com/agentsmd/agents.md/issues/53)
- [Maximiliano Contieri (Medium): AI Coding Tip 014 — Use Nested AGENTS.md Files](https://mcsee.medium.com/ai-coding-tip-014-use-nested-agents-md-files-23031bb0786a)
- [GitHub Blog: How to write a great agents.md — lessons from 2,500+ repositories](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [Linux Foundation AAIF Announcement](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation)
