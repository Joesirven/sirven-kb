---
title: "Agent Tooling Conventions — research cluster"
type: readme
status: research-complete
updated: 2026-06-08
topic_cluster: agent-tooling-conventions
---

# Agent Tooling Conventions — cluster index

Deep-research runs on agent instruction files, skill architecture, KB convention enforcement, personal vs. team context separation, and org-wide skill distribution. 30+ sources fetched and adversarially verified across four research runs.

## Files

| File | Focus | as_of | revisit_when |
|---|---|---|---|
| `per-tool-agent-files.md` | Full synthesis: TL;DR, per-tool mechanics table, symlink vs import patterns, progressive disclosure, anti-patterns, ETH Zurich study interpretation, sources | 2026-06-08 | 2026-12-01 or when AGENTS.md standard ships a major revision |
| `skills-and-modules.md` | Full synthesis: SKILL.md structure (3-level progressive disclosure), thin-skill→module pattern, scheduled vs. capability separation, KB convention enforcement, deep-research/obsidian-kb/kb-audit family analysis, 15+ sources | 2026-06-08 | 2026-12-01 or when Anthropic ships SKILL.md spec changes |
| `kb-repo-interaction.md` | Personal Obsidian vault ↔ shared Bitbucket repo interaction model: team-shared vs. personal split, global layers (~/.claude/CLAUDE.md, Cursor User Rules), CLAUDE.local.md, .git/info/exclude pattern, MCP-based vault access, concrete 7-step setup for Jose | 2026-06-08 | 2026-12-01 |
| `company-skill-sharing.md` | Plugin marketplace distribution mechanism for org-wide skill sharing: Bitbucket private marketplace setup, versioning via git tags, cache gotcha, practitioner quotes (Spence 84% activation finding, Castillo zero-friction pattern, Böttger private-repo credential guidance), concrete Catalist recommendation | 2026-06-08 | 2026-12-01 |

## Key conclusions (one-liners)

1. AGENTS.md is the open standard; Claude Code needs a `@AGENTS.md` import in CLAUDE.md — the "fallback" claim is wrong.
2. Per-tool overlays (Cursor MDC, Claude `.claude/rules/`) are for tool-specific features AGENTS.md cannot express, not for duplicating shared content.
3. Keep files < 200 lines, hand-curated, command-focused. Auto-generation hurts performance (ETH Zurich 2026).
4. Skills use 3-level progressive disclosure: frontmatter (~100 tokens always), SKILL.md body (<5k on trigger), references/ on demand.
5. Thin skills pointing to `references/` modules is a confirmed, production-proven pattern — not speculation.
6. Scheduled Tasks / Routines are trigger layers; Skills are capability layers. Never mix them in the same SKILL.md.
7. KB convention enforcement through skills works: encode taxonomy + naming + frontmatter schema as executable instructions in a docs-organizer subagent.
8. Skills are high-probability guidance, not guaranteed execution (HN adversarial signal). Design for safe failure paths.
9. The private vault and shared repos are independent trees that never reference each other in committed files. Vault context reaches the agent via `~/.claude/CLAUDE.md` imports or an Obsidian MCP server — both machine-local, zero repo footprint.
10. Personal agents/skills for shared repos: private `claude-configs/` repo + symlinks hidden via `.git/info/exclude` (not `.gitignore`) — teammates never see them.
11. Skills are shared via **plugin marketplaces** (git repo + marketplace.json), NOT by committing `.claude/skills/` to a shared repo — committed source is not installed source. Bitbucket: `git@bitbucket.org:org/repo.git`; zero-friction rollout via `extraKnownMarketplaces` + `enabledPlugins` in `.claude/settings.json`.
