---
title: "Company-wide Claude skill sharing — distribution, install, versioning"
type: synthesis
status: research-complete
as_of: 2026-06-08
revisit_when: 2026-12-01 or when Anthropic ships breaking plugin-system changes
source_url:
  - https://code.claude.com/docs/en/plugin-marketplaces
  - https://code.claude.com/docs/en/discover-plugins
  - https://dominic-boettger.com/blog/claude-code-private-plugin-marketplace-guide/
  - https://scottspence.com/posts/organising-claude-code-skills-into-plugin-marketplaces
  - https://medium.com/@pekastel/shared-skills-shared-success-how-claude-code-plugins-embed-team-expertise-5012bc0ff232
  - https://news.ycombinator.com/item?id=45530150
  - https://github.com/anthropics/claude-plugins-official
  - https://gist.github.com/gwpl/103c997128c6b6a6102e2a4a6cf8d283
topic_cluster: agent-tooling-conventions
---

# Company-wide Claude Skill Sharing — Distribution, Install, Versioning

## Signal-first TL;DR

**The canonical answer (Oct 2025 onward):** skills travel via **plugins**; plugins travel via **plugin marketplaces**. A marketplace is a git repo with a `.claude-plugin/marketplace.json` index file. Teammates add the repo once (`/plugin marketplace add`) and install individual plugins (`/plugin install`). The "source-in-repo does not equal installed" gap is the central gotcha — committing `.claude/skills/` to a shared repo makes the source visible but **does not install the skill** for any teammate. A plugin/marketplace is the only mechanism that crosses from source-available to installed-and-active.

For Bitbucket-hosted private repos (the Catalist case), the flow is identical to GitHub except you use a full git URL:
```
/plugin marketplace add git@bitbucket.org:company/agent-kb-skills.git
```
Claude Code reuses the system SSH agent — if `git clone` works in terminal it works in Claude Code.

---

## 1. The Sharing Mechanism — Plugin Marketplaces

### How a marketplace works (official Anthropic docs, 2025)

A plugin bundles one or more skills + optional MCPs, commands, hooks, or agents into an installable unit. A **marketplace** is a catalog (a `marketplace.json` file in a git repo) that tells Claude Code where to find plugins.

Install flow for a teammate:
1. `/plugin marketplace add <source>` — registers the catalog locally (no plugins installed yet; analogous to adding an app store).
2. `/plugin install <plugin-name>@<marketplace-name>` — pulls and caches the plugin (`~/.claude/plugins/cache/`); skills become active.
3. `/reload-plugins` — hot-reloads within a running session without restart.

Scope options at install time:
- **User scope** — active for all projects on this machine.
- **Project scope** — written to `.claude/settings.json`; shared with all collaborators who clone the repo.
- **Local scope** — machine-local only, not shared.
- **Managed scope** (enterprise) — pushed by admin, cannot be overridden by developer.

### Marketplace source types (official docs)

| Source type | Command | Best for |
|---|---|---|
| GitHub (public) | `/plugin marketplace add owner/repo` | OSS / community |
| GitHub (private) | `/plugin marketplace add owner/repo` + `gh auth` or SSH key | Small team on GitHub |
| Bitbucket / GitLab / self-hosted | `/plugin marketplace add git@bitbucket.org:org/repo.git` | Private infra (Catalist case) |
| Local cloned path | `/plugin marketplace add /Users/name/dev/plugins` | Dev-loop / offline |
| Remote URL | `/plugin marketplace add https://example.com/marketplace.json` | Hosted JSON (limited) |

SSH note: Claude Code suppresses interactive SSH prompts. Key must be in `ssh-agent` and host must be in `~/.ssh/known_hosts` before Claude Code first connects.

### The plugin-marketplace flow end-to-end (for org rollout)

```
agent-kb-base (Bitbucket)
  └── .claude-plugin/
      └── marketplace.json          ← catalog registry
  └── plugins/
      └── <plugin-name>/
          └── skills/
              └── <skill-name>/
                  └── SKILL.md      ← the actual skill
```

**One-time per machine (teammate setup):**
```sh
/plugin marketplace add git@bitbucket.org:company/agent-kb-base.git
/plugin install catalist-workflows@agent-kb-base
```

**Automatic via project settings (zero-friction path):**
Add to the shared repo's `.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "agent-kb-base": {
      "source": {
        "source": "github",
        "repo": "company/agent-kb-base"
      }
    }
  },
  "enabledPlugins": {
    "catalist-workflows@agent-kb-base": true
  }
}
```
When a teammate opens Claude Code in the repo and trusts the directory, Claude Code prompts to install the configured marketplace and plugins — no manual `/plugin install` required.

---

## 2. Versioning and Update Propagation

### Git-tag versioning (practitioner consensus, Jan 2026)

Dominic Böttger (Jan 20, 2026): "Use Git tags to version your marketplace: `git tag -a v1.2.0 -m 'Added planner:sprints skill'` — this lets teams pin to specific versions if needed."

To pin to a specific release:
```sh
/plugin marketplace add git@bitbucket.org:company/agent-kb-base.git#v1.2.0
```

### Auto-update behavior

- Official Anthropic marketplaces: auto-update **on** by default.
- Third-party / local marketplaces: auto-update **off** by default (dev-friendliness, to avoid silent changes).
- To enable auto-update on a private marketplace, toggle it in `/plugin` > Marketplaces tab, or set in managed settings:
  ```json
  { "extraKnownMarketplaces": { "agent-kb-base": { "autoUpdate": true, ... } } }
  ```
- When auto-update fires, developers see a notification prompting `/reload-plugins`.

### Manual update pull (most common for private org repos)

```sh
/plugin marketplace update agent-kb-base
```
This re-fetches the catalog from the git remote and upgrades installed plugins to their latest versions. Equivalent to: pull the marketplace repo, re-clone plugin sources.

### The cache gotcha

Plugins are copied to `~/.claude/plugins/cache/` keyed by **plugin name + version**. If you edit source files in the plugin repo but don't bump the version in `plugin.json`, Claude Code serves the stale cached copy silently. The vault's "read-only cache" manifests here: files you see in `~/.claude/plugins/cache/` are the installed snapshot, not the live source. Edits to those cached files are overwritten on next install.

**Fix:** bump `plugin.json` version with every meaningful edit, OR during active dev use a local path marketplace (edits reflect immediately because the plugin is loaded in-place, not copied to cache):
```sh
/plugin marketplace add /Users/jose/dev/agent-kb-base   # local clone
```

Known bug (Feb–Mar 2026, issue #27332 on anthropics/claude-code): plugin skill `references/` are sometimes resolved against `.claude/skills/` instead of the plugin cache. Workaround: keep references inside the plugin directory and use relative paths only.

---

## 3. Real Practitioners

### Scott Spence (@spences10) — Jan 24, 2026
Post: "Organising Claude Code Skills Into Plugin Marketplaces" (scottspence.com)

Key quote: "I needed these skills and 'bits' tracked in git and to be able to sync them across projects and pull them when I needed them, rather than setting up sync between them all — there's plugins you can make for Claude Code to consume."

Before plugins: skills "dotted around in differing repos," copy-pasting between projects, outdated versions. After: two public GitHub marketplace repos (`spences10/claude-code-toolkit`, `spences10/svelte-skills-kit`) — domain-split rationale: general vs. framework-specific to avoid context bloat.

Key finding on skill activation: "The forced-eval hook in toolkit-skills makes the Svelte skills actually activate when they should (84% vs 20% without it)" — skill activation without a forced-eval hook is unreliable. The hook is itself a plugin skill. **Implication for org rollout: ship a forced-eval hook as part of the base plugin.**

### Pablo Castillo (@pekastel) — Oct 28, 2025
Post: "Shared Skills, Shared Success: How Claude Code Skills Embed Team Expertise" (Medium)

Key quote on zero-friction distribution: "Developers don't need to do anything. They clone the repo, Claude Code reads that settings file, and the plugins are there — part of the repository, not something they installed. The marketplace is defined, the plugins are activated, and everyone on the team has access to that expertise automatically. No friction. No extra steps."

Identified the maintenance risk: "Someone has to own each plugin. Someone has to keep the Skills current as your organization learns better patterns… The system only works as well as the weakest link in your knowledge chain."

### Dominic Böttger — Jan 20, 2026
Post: "Building a Private Claude Code Plugin Marketplace for Your Team" (dominic-boettger.com)

Key recommendation on private repos: "For private repos, the local marketplace approach is simpler and avoids credential headaches. [GitHub source option] may require changes to your Git credential manager configuration. If you're using the gh CLI with its default credential manager, these changes could cause conflicts."

Practical finding: local-path registration (`"source": "local", "directory": "/..."`) is the most reliable for private repos during the rollout phase; switch to SSH git URL once credentials are confirmed stable.

### joesaunderson (HN) — Oct 2025 (item 45544549)
Within 24 hours of Anthropic announcing plugins (Oct 2025), community marketplace sites proliferated. Community noted: "plugins and marketplaces have cropped up everywhere." The `anthropics/claude-plugins-community` repo consolidated third-party plugins with automated safety screening. Takeaway: the ecosystem moved fast; official docs are the stable reference; community repos have quality variance.

### Alex McFarland — Mar 16, 2026
Substack post: "You Need a Private Claude Plugin Marketplace (Cowork Guide)" — confirms the same local-repo-as-marketplace pattern, specifically addressing Cowork (Claude's team product). Notes that private repo support requires Team/Enterprise plan for the GitHub-source method in Cowork; for Claude Code CLI, SSH key method works on any plan.

---

## 4. What Doesn't Work (Gotchas and Anti-Patterns)

| Anti-pattern | Why it fails |
|---|---|
| Committing `.claude/skills/` to shared repo | Source is visible to teammates but skill is not installed — Claude Code does not auto-load from committed `.claude/skills/` unless skill was installed via plugin or manually placed in `~/.claude/skills/` |
| Editing files in `~/.claude/plugins/cache/` | Overwritten on next `/plugin marketplace update` or reinstall; changes lost |
| Symlinks from a private configs repo into `.claude/skills/` | Works locally; teammates who don't have the same configs repo get broken symlinks. Not a team solution |
| `extraKnownMarketplaces` without also setting `enabledPlugins` | Registers the catalog but does not install anything — developers still need to run `/plugin install` |
| Relying on `extraKnownMarketplaces` alone in `-p` (print/headless) mode | Trust dialogs are skipped and `extraKnownMarketplaces` may not be processed; only `known_marketplaces.json` (user cache) is consulted — known issue as of Feb 2026 |
| Using `"source": "github"` type for Bitbucket/GitLab repos | The github source type only works for github.com. Use full SSH or HTTPS URL for other hosts |

---

## 5. Recommendation for Catalist / Jose

### Recommended architecture: `agent-kb-base` as both skill source and private marketplace

**What to do:**

1. **Structure `agent-kb-base` as a plugin marketplace.** Add a `.claude-plugin/marketplace.json` at repo root listing one or more plugins. Each plugin wraps related skills (e.g., one plugin for KB-management skills, one for data-engineering workflows).

2. **Each teammate registers the marketplace once** using SSH (Bitbucket):
   ```sh
   /plugin marketplace add git@bitbucket.org:catalist/agent-kb-base.git
   ```
   Then installs:
   ```sh
   /plugin install catalist-kb@agent-kb-base
   ```

3. **Enable zero-friction onboarding** by committing this to `.claude/settings.json` in any repo that should have the skills active:
   ```json
   {
     "extraKnownMarketplaces": {
       "agent-kb-base": {
         "source": { "source": "git", "url": "git@bitbucket.org:catalist/agent-kb-base.git" }
       }
     },
     "enabledPlugins": { "catalist-kb@agent-kb-base": true }
   }
   ```
   New teammate clones repo → trusts directory → Claude Code prompts install → done.

4. **Version with tags.** Every skill update that should propagate: commit, tag (`v1.x.x`), push. Teammates run `/plugin marketplace update agent-kb-base` to pull latest. Enable auto-update for fire-and-forget propagation once the team trusts the cadence.

5. **Ship a forced-eval hook** as the first skill in the plugin (see Scott Spence's finding: 84% vs 20% activation without it). Without this, automatic skill triggering is unreliable.

6. **Local-path fallback for active development:** while iterating on skill content, register a local clone to get instant feedback without version-bump churn:
   ```sh
   /plugin marketplace add ~/dev/agent-kb-base
   ```
   Switch back to the git-URL registration for production rollout.

### Why not committed `.claude/skills/`?

Committed `.claude/skills/` in a shared repo puts source under version control but does **not** install the skills for any teammate. Each person would still need to manually copy or symlink into `~/.claude/skills/`. This is the single most common confusion in the practitioner discourse — it looks like sharing but requires manual per-machine action. The plugin/marketplace mechanism is the only mechanism that crosses from "committed source" to "installed and active."

### Why not symlinks from a private configs repo?

Works for a solo developer who maintains a separate `claude-configs` repo (the pattern from `kb-repo-interaction.md`). Breaks for teammates who don't have that repo. Not a team distribution mechanism.

### Why not liteLLM's managed skill marketplace?

LiteLLM documents a "plugin marketplace" pattern but this is a proxy-layer concern about routing, not Anthropic's native plugin system. Use native unless you're already on a liteLLM gateway.

---

## Appendix: Marketplace File Structure

Minimal `agent-kb-base/.claude-plugin/marketplace.json`:
```json
{
  "name": "agent-kb-base",
  "displayName": "Catalist Agent KB Skills",
  "plugins": [
    {
      "name": "catalist-kb",
      "description": "KB management, research, and Obsidian vault skills for Catalist agents",
      "source": "./plugins/catalist-kb",
      "skills": ["./skills/obsidian-kb", "./skills/deep-research", "./skills/kb-audit"]
    }
  ]
}
```

Plugin directory layout:
```
agent-kb-base/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    └── catalist-kb/
        └── skills/
            ├── obsidian-kb/
            │   └── SKILL.md
            ├── deep-research/
            │   └── SKILL.md
            └── kb-audit/
                └── SKILL.md
```
