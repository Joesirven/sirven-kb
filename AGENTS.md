# AGENTS.md — sirven-kb (root)

Rules for every agent, any tool (Claude Code / Cursor / Cowork). Cascades into every child `agents.md`. Read this + the local `agents.md` before acting. Detail lives behind pointers, not here.

## Invariants
- **Never send/post** without explicit approval (email/messages/posts → draft in `tmp/` + flag). **Never delete** files without confirmation; unattended runs never delete.
- **Secrets** (credentials, keys, tokens): never quote, copy, surface, or commit — anywhere.
- **Write/approval policy is per-directory:** the local `agents.md` defines what is freely editable vs. gated and lists append targets for that area.
- When in doubt: flag, don't act.

## How to work
- **Push back:** verify assertions; deliver pushback as sourced callouts inside the relevant doc. No speculative docs.
- **Game-master model:** plan → delegate to subagents (outputs → `tmp/`) → maker→checker review → apply. Parallelize; don't fan out inline. Rules: `Ops/System/modules/subagent-orchestration.md`.
- **Modules over duplication:** shared capability logic lives in `Ops/System/modules/`; skills are thin wrappers that pass parameters into modules.
- **Anti-proliferation:** search before creating; extend > new; ≤ ~5 primary notes per area root then subfolder; one canonical doc per topic.

## Git (this repo: `sirven-kb`)
- **Branch per task** (`agent/<slug>`); no multi-file work directly on `main`. **Parallel agents = one git worktree each**; game-master reviews the diff → merges → deletes the worktree.
- Conventional commits (`type(scope): msg`) + `Co-Authored-By: Claude` trailer. **Never** force-push, `reset --hard`, or commit secrets/`.env`.

## Map (each dir has its own agents.md — read it)
- `Ops/` — System = machinery (scheduled tasks + modules) · Career = goals/dev (gitignored).
- `Projects/<X>/` — per-project KBs (README + agents + ADRs) · `Meetings/` — episode notes; decisions promote to project ADRs.
- `Docs/` — general reference + wide-topic research syntheses · `Research/` — ALL source cards, centralized; syntheses route out.
- `tmp/` — scratch, subagent outputs, drafts-for-approval; swept periodically · `_Inbox/` · `_Personal/` (gitignored).

## Decisions & currency
Current decision for any topic = newest entry for that key in the nearest `decisions.md`. Record decisions as keyed append-only entries per `Ops/System/modules/decision-log.md`. No status flags — currency is inferred by recency-per-key.

## Conventions
Filenames: no spaces, ISO dates. `agents.md` = rules + process **+ a content index** (one line per file and per child folder in that directory, saying what each holds), every dir incl. leaves (children ≤ ~80 lines; this file ≤ ~45); `README.md` = human narrative. Scheduled specs: `Ops/System/ScheduledTasks/`.
Frontmatter schema (the `type`/`status` enums, per-type required fields): `_meta/FRONTMATTER-SCHEMA.md`.

**Retrieval and inheritance (how "update the knowledge base" works):** subdirectories are the taxonomy (categorize with folders, e.g. personas, workflows, tools, then deeper leaves as a category earns them), and every directory's `agents.md` indexes its own contents so an agent reads the thin index first and pulls only the file it needs (just-in-time). Thin at the top, specific in the leaves, the cascade loaded high, detail on demand. Full rule + examples: `_meta/RETRIEVAL-AND-INHERITANCE.md`.

## Language rule — no acronyms (Jose's standing order, 2026-07-08)
Never use unexplained acronyms in anything written here or in any agent-facing instruction:
spell out "knowledge base", "decision record", "work in progress", and so on. Universally-
lexicalized technical names (URL, JSON, SSH, API, iOS) and literal identifiers that must
match files or code (e.g. a file named `DEC-2026-00N-*`) are allowed, glossed in plain words
on first mention. Carry this rule verbatim into every `agents.md`, `CLAUDE.md`, skill, or
prompt you write or update.

Two additions with the same force (Jose, 2026-07-17), to carry forward the same way:
1. No nicknames or invented shorthand for tasks, concepts, projects, or things unless
   Jose introduced the name himself. Use the full, established name every time (the
   file name, the stream name Jose used, the product name). A coined codename or
   abbreviation of convenience is a name the reader has to reverse-engineer.
2. Em-dashes sparingly. Not banned, but rare: prefer commas, periods, colons, or
   parentheses. Most paragraphs should have zero; never more than one per paragraph.

## Session ritual
Every session that edits this vault ends with four steps: a session-tagged commit
(`<area>: <what> [session: <id>]`), an appended row in `00-OPS/AGENTS-LOG.md`, a state flip
of your session row in the meadow-postgres agent_state store —
`python3 ~/Projects/meadow/tools/agent_state.py flip <session-id> done`
(DATABASE_URL from the environment or `~/.meadow/state-store.env`; per Jose's 2026-07-17
order the state file that preceded the database is gone — state lives only in the database;
never recreate a state file) — and a run of `eval_session`. Full detail, and per-type
definitions of done: `00-OPS/PROCESSES.md`.
