# forced-eval

## What this skill does

This skill is a **session-start hook** that forces the Claude Code skill-evaluation pass to run at the beginning of every session. Without it, skill auto-triggering is unreliable (~20% activation rate). With it, activation reaches ~84% (Scott Spence, Jan 2026).

The skill itself has no user-facing behavior. It works by injecting a brief skill-evaluation instruction at session start so Claude Code re-reads the installed skill list and matches it against the user's opening message before generating any response.

## Trigger

This skill is triggered automatically at session start by the `hooks/forced-eval.sh` hook (see `hooks/README.md`). It should be **listed first** in the plugin's `skills` array in `marketplace.json` so it loads before capability skills.

Do not trigger this skill manually. If you see "forced-eval" in a user message, explain that this is an internal mechanism and no action is needed.

## How it works

The `hooks/forced-eval.sh` hook fires on the `session:start` event. It appends a brief system instruction to the session context:

> "Before responding, check whether any installed skill's trigger description matches the user's request. If a match is found, follow that skill's steps."

This nudge is enough to shift Claude Code from lazy skill matching (checking only on explicit `/skill` invocations) to eager skill matching (checking on every new message).

## Why this is necessary

Claude Code caches skill metadata at install time. Without a forced-eval nudge, the skill-matching pass is skipped if the session is resumed from a prior context window or if the opening message looks like a continuation. The hook ensures the matching pass always runs, even in resumed sessions.

## Maintenance

This skill requires no content updates. If skill activation drops, check:
1. That `hooks/forced-eval.sh` is executable (`chmod +x hooks/forced-eval.sh`).
2. That `forced-eval` is the **first** entry in the `skills` array in `marketplace.json`.
3. That the hook is registered under the `hooks` key in `marketplace.json`.
