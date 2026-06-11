# hooks/

Hooks that fire on Claude Code lifecycle events. Currently one hook is shipped with the `kb-workflows` plugin.

## forced-eval.sh

**Event:** `session:start`
**Effect:** Injects a skill-evaluation instruction at the start of every session, raising skill auto-trigger rate from ~20% to ~84%.

### What it does

Without a forced-eval nudge, Claude Code's skill matching runs lazily — skills only activate when explicitly invoked or when the model happens to check them. This hook fires on every `session:start` event and writes a brief system instruction telling Claude Code to evaluate all installed skills against the user's opening message before generating any response.

### How it is wired

The hook is registered in `.claude-plugin/marketplace.json` under the plugin's `hooks` key:

```json
"hooks": [
  { "event": "session:start", "command": "./hooks/forced-eval.sh" }
]
```

Claude Code reads this at plugin-load time. When a new session starts, it calls the hook script, captures its stdout, and prepends the output to the session context as a system message.

### Setup

The script must be executable before it can fire:

```sh
chmod +x hooks/forced-eval.sh
```

If you installed via `/plugin install`, Claude Code sets the executable bit automatically. If you cloned manually or pulled via a local-path marketplace, run the chmod once.

### Troubleshooting

| Symptom | Check |
|---|---|
| Skills rarely auto-trigger | Confirm `forced-eval` is listed **first** in the `skills` array in `marketplace.json` |
| Hook fires but has no effect | Confirm `hooks/forced-eval.sh` is executable (`ls -l hooks/`) |
| `session:start` event not received | Confirm the `hooks` key is present in `marketplace.json` and the plugin is installed (not just the marketplace registered) |
| Changes to hook not reflected | Bump the plugin version in `marketplace.json`, reinstall, or use a local-path marketplace during dev |
