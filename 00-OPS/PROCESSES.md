---
title: "Session processes — definitions of done"
type: ops
status: active
updated: 2026-07-12
tags: [ops, session-ritual, definition-of-done]
---

# Session processes

What "done" means for a session in this vault, and what "done" means for each document type.
Pointed to from the root `AGENTS.md`; this file carries the full detail.

## The four-part session ritual

Every session that edits this vault ends with all four of these steps, in order:

1. **Session-tagged commit.** The final commit (or every commit, if you split the session
   into several) uses the format `<area>: <what> [session: <id>]` — for example
   `base: add frontmatter schema, personas, session ritual [session: reconcile-s4-base-hardening-2026-07-12]`.
   Conventional-commit scoping (`type(scope): msg`) does not satisfy this — the literal
   `[session: <id>]` tag must be present.
2. **`AGENTS-LOG.md` append.** Append one row to `00-OPS/AGENTS-LOG.md` recording the date,
   session id, agent, and a one-line summary of what the session did. Append-only — never
   edit or remove an existing row.
3. **`agents.json` state flip.** Flip this session's entry in `00-OPS/_state/agents.json` to
   `done` (or `error`, if it ended badly), matching the shape in
   `~/Projects/meadow/schema/agents.schema.json` (a sibling repository, not part of this base).
4. **Run `eval_session`.** From the vault root, run
   `python3 ~/Projects/meadow/tools/eval_session.py <first-commit>..<last-commit>` to score the
   session against this document and append the result to an evaluation log. The tool lives
   in the Meadow repository — this vault's own `README.md` already points to Meadow for
   tooling; this is the same pattern.

A session is not done until all four steps have happened, in this order, for real — not just
described as intended.

## Per-type definition of done

These mirror the type-specific required fields in `_meta/FRONTMATTER-SCHEMA.md`.

- **`research`** — `citation`, `url`, `topic_cluster`, and `published` are all present in
  frontmatter, and the "Source quality / limitations" section (see
  `Research/PAPER-TEMPLATE.md`) is actually filled in, not left as a template placeholder.
- **`data`** — `pii` (`true`/`false`) and `license_terms` are both declared in frontmatter;
  a document describing personally-identifying data without `pii: true` is not done, it is
  wrong.
- **`library`** — `topic` is declared, and the capture is filed under the matching topic
  folder.
- **`architecture`** — if `status: locked`, no further change lands without a decision
  recorded first (see `Ops/System/modules/decision-log.md`, and
  `Ops/System/modules/decision-schema-scorable.md` for the opt-in scorable tier).
- **`meta`** (schemas, personas, contribution rules) — the document accurately describes the
  current state of the base; a `meta` document that drifts from what the base actually does
  is not done, it needs a follow-up edit.
- **Any type** — base frontmatter fields (`title`, `type`, `status`, `updated`) are present
  and `type`/`status` are each one value from the enums in `_meta/FRONTMATTER-SCHEMA.md`.

## Where this is enforced

`eval_session` (Meadow repository) reads this file's ritual description to score a session;
the frontmatter validator (also Meadow) reads `_meta/FRONTMATTER-SCHEMA.md`'s enums. Both
tools are read-only inputs from this vault's perspective — they live and are maintained in
the Meadow repository, not here.
