# kb-workflows plugin

Bundles KB management, research, and vault-health skills into a single installable plugin.

## Skills included

| Skill | Triggers on |
|---|---|
| `forced-eval` | Session start (auto, via hook) — raises skill activation rate ~20% → 84% |
| `deep-research` | "research X", "add sources", "deep dive", "populate KB on", "fill in research gaps" |
| `obsidian-kb` | "check the KB", "look up X in the vault", "add this to research", "update the knowledge base" |
| `kb-audit` | "audit the KB", "check KB health", "find stale docs", "find orphan files", "clean up the KB" |
| `meeting-prep` | Pre-meeting prep requests |
| `meeting-ingestion` | Post-meeting notes ingestion |
| `inbox-triage` | Email inbox triage |
| `issue-draft` | Issue / ticket drafting |
| `staleness-check` | Upstream doc drift detection |

## Install

**Step 1 — Register the marketplace (once per machine):**

```sh
# Git URL (SSH) — recommended for private repos:
/plugin marketplace add git@<host>:<org>/agent-kb-base.git

# Local clone — use during active development (edits reflect immediately):
/plugin marketplace add /path/to/local/agent-kb-base
```

**Step 2 — Install the plugin:**

```sh
/plugin install kb-workflows@agent-kb-base
```

**Step 3 — Make the hook executable (if not set automatically):**

```sh
chmod +x hooks/forced-eval.sh
```

**Optional — zero-friction for shared repos.** Add to `.claude/settings.json` in any repo where these skills should be active by default. Teammates who clone the repo and trust the directory are prompted to install automatically — no manual `/plugin install` needed:

```json
{
  "extraKnownMarketplaces": {
    "agent-kb-base": {
      "source": { "source": "git", "url": "git@<host>:<org>/agent-kb-base.git" }
    }
  },
  "enabledPlugins": { "kb-workflows@agent-kb-base": true }
}
```

## Update

```sh
/plugin marketplace update agent-kb-base
```

This re-fetches the catalog from the git remote and upgrades installed plugins to their latest versions. If auto-update is not enabled, teammates must run this command to pull skill changes.

To enable auto-update (fire-and-forget after initial setup):

```json
{ "extraKnownMarketplaces": { "agent-kb-base": { "autoUpdate": true, ... } } }
```

## Version pinning

To pin to a specific release rather than tracking `main`:

```sh
/plugin marketplace add git@<host>:<org>/agent-kb-base.git#v1.1.0
```

Tags follow semver. Patch = skill content edits. Minor = new skills added. Major = breaking restructure.

## Cache-staleness gotcha

Plugins are cached at `~/.claude/plugins/cache/` keyed by **plugin name + version**. If you edit skill source files but do not bump the version in `marketplace.json`, Claude Code serves the stale cached copy silently.

**Fix options:**
1. Bump `"version"` in `.claude-plugin/marketplace.json` with every meaningful edit, then run `/plugin marketplace update agent-kb-base`.
2. During active development, register a **local-path marketplace** instead of the git URL. Local-path marketplaces load skills in-place (no cache copy), so edits reflect immediately without version bumps:
   ```sh
   /plugin marketplace add /path/to/local/agent-kb-base
   ```
   Switch back to the git-URL registration for production rollout.

## Reload without restart

To hot-reload skills within a running session after an update:

```sh
/reload-plugins
```
